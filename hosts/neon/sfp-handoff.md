# Neon (Dell Edge 610 / VEP1400) — SFP port investigation — HANDOFF

> This doc is for an agent (or Franta) picking up the Dell Edge 610 SFP
> debugging. Read the **TL;DR** and **Next steps** first. Everything else is
> the trail of what was established and ruled out so you don't re-walk it.

## TL;DR — confirmed root cause and tested fix

- **Goal:** get the Edge 610's SFP port(s) to link under NixOS/stock Linux the
  same way they link in Dell DiagOS.
- **Status: CONFIRMED on hardware.** With the same SFP, cable, and live 1G
  partner, applying the two DiagOS SFP TX-enable writes on NixOS changed `eno4`
  from `NO-CARRIER` to **`LOWER_UP`, 1000 Mb/s full duplex**. `dmesg` logged
  `NIC Link is Up 1 Gbps`.
- **Root cause:** the VEP1400 CPLD defaults both SFP cages to **TX_DISABLE**.
  DiagOS `/etc/rc.local` clears those bits at boot; stock NixOS does not.
  NixOS initially read `0x31:0x10 = 0x80` (bit 7 set / TX disabled). The exact
  DiagOS-equivalent writes changed it to `0x00` and restored link.
- **Exact tested fix** (DiagOS i2c bus 1 maps to NixOS iSMT bus 0):

  ```sh
  modprobe i2c-dev
  i2cset -y 0 0x31 0x10 0x00 b
  i2cset -y 0 0x31 0x11 0x00 b
  ```

  These are normal CPLD writes only: **no `rmmod`, no PCI rescan, no driver
  patch, and no reboot is needed for the live fix.**
- **Do not deploy** the `cu_sfp_as_sx` patch or the `0x31:0x01` Gris-platform
  reinit. Both are unrelated to this 610; the latter caused a 5.10 AER oops.

## The goal (context)

Add host **neon** (Dell Edge 610) to this repo as a server, and make its SFP
ports usable. The SFP link problem is the blocker. (Adding neon to
`flake.nix` `serverHosts` + `hosts/neon/default.nix` etc. is still pending and
is separate from the SFP work.)

## Hardware — Dell EMC EDGE610-CPU (VEP1400)

- CPU: Intel Atom C3000 (Avoton/Denverton platform). BIOS `3.43.0.9-11`.
- NIC: **four Intel X553** backplane functions, all driven by `ixgbe`.
  Plus an **on-board Marvell 88E6190** switch behind two of them (6 RJ45).

| BDF         | Subsys | Interface (name shifts on reload) | Role                                                    |
|-------------|--------|-----------------------------------|---------------------------------------------------------|
| 03:00.0     | 0x0000 | eno1                              | CPU uplink **into** the 88E6190 switch                  |
| 03:00.1     | 0x0000 | eno2                              | CPU uplink **into** the 88E6190 switch                  |
| 05:00.0     | 0x15c4 | eno3                              | **SFP cage** — direct MAC, NOT behind the switch        |
| 05:00.1     | 0x15c4 | eno4                              | **SFP cage** — direct MAC (module was in this one)      |

- The SFP ports are **direct MACs** → they do **not** need DSA. (DSA/MDIO
  exposure of the 88E6190 is only needed for the 6 RJ45 ports; that's a much
  bigger kernel+DT effort — see `../installer-iso/edge610-notes.md`.)
- **Identify the SFP port by BDF `05:00.x` / by `ethtool -m`**, not by name —
  the `enoN` names reassign on module reload/rescan.

## The SFP module

- **DELL FCLF8521P2BTL-DL** ("1G SFP, 1000Base‑T 100 m, Copper RJ‑45"),
  Vendor OUI `00:90:65`, rev A0.
- `sudo ethtool -m <sfp-if>` reads the EEPROM **fine**: Identifier `0x03 (SFP)`,
  Connector `0x22 (RJ45)`, Transceiver type **`Ethernet: 1000BASE-T`**.
  → The module is powered and its I2C/EEPROM is reachable. That does **not**
  prove its transmit path is enabled: TX_DISABLE is a separate VEP1400 CPLD
  control bit. The failure was that control bit, not EEPROM visibility.
- It is a **1000BASE‑T** (copper) module: on the SFP side it presents a
  **1000BASE‑X** serial interface to the X553, and converts to RJ45 copper on
  the cable side. **It needs a live 1G partner on its RJ45 to show a link.**

## What we established (facts, verified on the box)

- Kernel **5.10.269** (nixpkgs `nixos-26.05`, flake rev
  `241313f4e8e508cb9b13278c2b0fa25b9ca27163`). This is *pre* the AN‑37 SFI
  regression (commit `565736048bd5`, a **6.1+** thing), so the 5.10 SFI setup
  path should be healthy. `ixgbe` is a **loadable module** (vermagic
  `5.10.269 SMP mod_unload`, no modversions).
- **Driver view of the SFP:** `ethtool <sfp-if>` shows
  `Supported link modes: 1000baseKX/Full`, `Port: Other`, `Transceiver:
  internal`, `Link detected: no`. → The driver classifies it as **1g_sx (1G
  serial)** and configures the SFI for 1000baseKX. This is the *correct*
  classification for the SFP's serial side; the driver is behaving as intended.
- **Board ID:** `sudo i2cget -y 0 0x31 0x0` = `0x50` → binary `01010000` →
  **boardtype (low nibble) = `0000`**. `0x31 reg1` reads `0xff`.
- **Watchdog:** board reboots every ~5 min until disabled. Register `0x22` on
  **bus 0**. During testing the box was up 29+ min → **watchdog currently
  quiet** (already disabled). Disable cmd (this box's numbering):
  `sudo i2cset -y 0 0x22 0 0 b` (DiagOS uses bus 1 / `i2cset -y 1 0x22 0 0 b`).
- **I2C map** (load `i2c-dev` first: `sudo modprobe i2c-dev`; `/dev/i2c-*` is
  root‑only → use `sudo`):
  - **bus 0** = `SMBus iSMT adapter at dff3c000`: devices `0x20–0x2a`
    (CPLD/PIC cluster; **0x22 = watchdog**), `0x2d`, **`0x31`** (board CPLD —
    board ID / reinit), `0x40`, `0x4a`, `0x50–0x57`.
  - **bus 1** = `SMBus I801 adapter at f000`: `0x08`, `0x36`/`0x37` (UU),
    `0x44`, `0x54` (UU) — LPC/SPD. No `0x31` here.
  - **Numbering gotcha:** DiagOS calls the iSMT bus "1"; on this NixOS box it's
    **bus 0**. `sudo i2cget -y 1 0x31 0x0` fails; `sudo i2cget -y 0 0x31 0x0`
    works. Translate DiagOS bus numbers accordingly.

## Confirmed DiagOS behavior and NixOS proof

DiagOS uses an out-of-tree Dell driver (`ixgbe 5.3.7-Dell vep1400 MDIO access
mod`, kernel 4.9.30), but the SFP enable responsible for this result is a
plain userspace action in `/etc/rc.local`, not an opaque driver operation:

```sh
# /etc/rc.local lines 109–112
# turn off tx-disable
echo "vep1400 enable SFP TX power.." > /dev/kmsg
i2cset -y 1 0x31 0x10 0x00 b
i2cset -y 1 0x31 0x11 0x00 b
```

The DiagOS platform list defines these registers:

| CPLD register | Meaning | Required value |
|---|---|---|
| `0x31:0x10` | SFP port 0; bit 7 = TX_DISABLE | `0` clears TX_DISABLE / enables TX power |
| `0x31:0x11` | SFP port 1; bit 7 = TX_DISABLE | `0` clears TX_DISABLE / enables TX power |

The populated cage is `05:00.1` (`eth3` in DiagOS, `eno4` in NixOS) and maps
to `0x31:0x10`. DiagOS's known-good values were `0x10=0x00`, `0x11=0x07`
(the lower bits are read-only status; the other cage was empty). NixOS before
the writes read `0x10=0x80`, `0x11=0x87`—bit 7 was asserted on both cages.
After the exact writes NixOS read `0x10=0x00`, `0x11=0x07` and linked at 1G.

## What we tried (and why it didn't work)

### 1. Kernel driver patch `cu_sfp_as_sx` — RULED OUT (no-op)

- Built on the (older) theory that stock `ixgbe` refuses 1G *copper* SFPs on
  X550EM. Patch (adapted for 5.10 from the 2022 Silicom/netdev patch, not
  upstream) adds a `cu_sfp_as_sx` module param that remaps `1g_cu_core{0,1}` →
  `1g_sx_core{0,1}` in `ixgbe_supported_sfp_modules_X550em()` in `ixgbe_x550.c`.
  File: `patches/ixgbe-1g-cu-sfp-as-sx.patch` (3 files: `ixgbe_main.c`,
  `ixgbe_type.h`, `ixgbe_x550.c`).
- Baked into a diagnostic ISO (`./edge610-cusfp.iso`); **verified the patch is
  actually in the ISO's `ixgbe.ko`** (strings show the param + modinfo).
- **Why it's a no-op here:** the driver never classifies the FCLF8521 as
  `1g_cu`. It goes straight to `1g_sx` (see `ethtool` → 1000baseKX). The remap
  code path is only reached for `1g_cu`, so it never fires — confirmed by the
  absence of the patch's `"treating 1G Cu SFP as 1G SX"` pr_warn in dmesg.
- Side note: on this ISO **no** loaded module exposes
  `/sys/module/<mod>/parameters/` (checked ptp, libphy, mdio too) — a
  system‑wide quirk of this 5.10 build, *not* related to the patch. Don't use
  `/sys/.../parameters` as a signal here.
- **Conclusion:** the driver is not the blocker. Drop this thread.

### 2. DiagOS `0x31` backplane reinit — RULED OUT (and DANGEROUS)

- DiagOS snippet (provided by Franta) reads board ID from `i2c 0x31 reg 0` and,
  for the **"Gris" boardtypes** (`1000`/`1010`/`1011`), does:
  `rmmod ixgbe` → `i2cset -y 1 0x31 0x1 0xff` → PCI rescan (loop until `igb`
  present) → `modprobe ixgbe`. It does **nothing** for `1001` / `1100..1111`
  and prints "Unknown Board Type" for everything else.
- **Our boardtype is `0000`** → falls into the `*` "Unknown" branch → the
  DiagOS script performs **no reinit** on this board. (The Gris branch targets a
  Marvell‑PHY + I350/`igb` board — a different NIC, not our X553/`ixgbe`.)
- **Tested it anyway** (translated to bus 0): `rmmod ixgbe`; `i2cset -y 0 0x31
  0x1 0xff`; `echo 1 > /sys/bus/pci/rescan`; `modprobe ixgbe`.
  **Result: kernel Oops** — NULL‑pointer deref in the PCIe AER handler
  (`aer_isr → find_source_device → pci_walk_bus`, offset 0x28), triggered by the
  PCI rescan racing the reinit's bus disturbance. The box survived (oops was in
  an IRQ kthread) but is now **Tainted**. **`eno4` still had no carrier** and no
  `Link is up`/carrier event appeared.
- **Conclusion:** not the fix for the 610, and harmful. Do **not** repeat the
  0x31 write + PCI rescan on this board.

## Remaining hypotheses

Resolved for the tested SFP/cable/partner: the missing CPLD TX-enable is the
root cause. If another SFP or cage still fails after the two writes, first
verify its matching CPLD register has bit 7 clear and that it has a live RJ45
partner before investigating module or SerDes faults.

## Next steps — permanent NixOS implementation

1. Keep the **two exact writes** above; they are the proven fix. Do not add
   PCI rescan, module reload, or the `cu_sfp_as_sx` patch.
2. Make the setup robust to i2c bus-number ordering: find the adapter whose
   `name` is `SMBus iSMT adapter at dff3c000` rather than blindly assuming
   bus 0.
3. In neon's eventual `default.nix`, load `i2c-dev`/`i2c-ismt` and add an
   idempotent oneshot systemd service, ordered after
   `systemd-modules-load.service` and before `network-pre.target`. It should
   wait for the iSMT adapter, identify its bus number, and run:

   ```sh
   i2cset -y "$bus" 0x31 0x10 0x00 b
   i2cset -y "$bus" 0x31 0x11 0x00 b
   ```

   DiagOS performs these after `ixgbe` has already probed, so there is no need
   to delay or reload ixgbe.
4. Build a **clean** test ISO without the irrelevant ixgbe patch but with the
   service, then validate cold boot carrier, `ethtool`, ping, and `iperf3`.
5. Repeat across several cold boots before committing the same service to neon.

## How to operate the box

- **Control channel = serial** (headless, no VGA): `/dev/cu.usbserial-0001`,
  **115200 8N1**. Micro‑USB serial. Tooling on the Mac:
  - `/tmp/iso/ser` — python3 wrapper (points at store pyserial).
  - `/tmp/iso/srun.py <cmd...>` — runs commands with start/end markers, returns
    captured stdout. Usage: `/tmp/iso/ser /tmp/iso/srun.py 'echo hi' 'lsmod'`.
  - `/tmp/iso/probe.py` — just check the box is at a prompt.
  - Login: `nixos` (ISO). `sudo -n` works (no password; `wheelNeedsPassword
    = false`).
- **The diagnostic ISO** (`hosts/installer-iso/`, built as
  `.#nixosConfigurations.installer-iso.config.system.build.images.iso-installer`):
  5.10.269, serial console baked in (`console=ttyS0,115200n8`), SSH enabled
  (user `nixos`), plus `ethtool`, `i2c-tools`, `pciutils`, `net-tools`,
  `iputils`, `iperf3`, `lm_sensors`, `smartmontools`, and an `edge610-diag`
  script. The current ISO also carries the now-proven-irrelevant
  `cu_sfp_as_sx` patch + `modprobe.d/ixgbe` option; the next ISO should remove
  those and add the CPLD TX-enable service instead.
  - Current build: `./edge610-cusfp.iso` — sha256
    `8a69f58bd6a2d20a03f689f88a9a7a8f0ddecb415777adc5f48efeeb065c87bb`.
  - Older (unpatched): `./edge610-diag-5.10.iso`.
- **I2C:** `sudo modprobe i2c-dev` (for `/dev/i2c-*`), then `sudo i2cdetect -y
  0|1`, `sudo i2cget -y 0 0x31 0x0`, etc. (root‑only; bus 0 = iSMT).
- **Safe vs risky:** reads (`i2cget`, `i2cdetect`, `ethtool -m`, `dmesg`) are
  fine. The **two documented TX-enable writes** at `0x31:0x10` and `0x31:0x11`
  are proven safe and required. Other board-CPLD writes remain risky:
  specifically, do **not** pair the `0x31:0x01` Gris reinit with PCI rescan—it
  crashed the 5.10 AER handler. Keep the watchdog (`0x22`) in mind.

## Files & artifacts

- `patches/ixgbe-1g-cu-sfp-as-sx.patch` — ruled-out driver patch; remove it
  from future diagnostic/neon kernel configuration after the clean-service ISO
  test.
- `hosts/installer-iso/edge610-diag.nix` — ISO module (5.10, kernelPatches,
  modprobe.d/ixgbe, systemPackages, serial via `../installer-iso/default.nix`
  `boot.kernelParams`).
- `hosts/installer-iso/edge610-diag.sh` — on-box diag script (has a known PATH
  bug, low priority).
- `hosts/installer-iso/edge610-notes.md` — the original runbook / decision tree
  (H1 cage-held-off vs H2 AN‑37 regression) + watchdog + DSA reality check.
  **Read this too — it has the DSA/88E6190 analysis for the RJ45 ports.**
- `hosts/installer-iso/default.nix` — ISO host (serial console, SSH, hostname
  `nixos-installer`).
- `./edge610-cusfp.iso`, `./edge610-diag-5.10.iso` — built ISOs (git‑ignored via
  `*.iso`).
- Mac scratch (may be gone after reboot/GC): `/tmp/ixgbe/` (v5.10 ixgbe source),
  `/tmp/patch/{a,b}/` (a=unpatched, b=patched trees), `/tmp/iso/` (serial
  tooling).

## Sources

- STH thread (VEP1400 / Edge 610/620): `forums.servethehome.com` t/39392
  (XenForo; `#post-3698844` = watchdog-disable summary). Mostly watchdog-focused.
- OpenWrt mirror (Discourse, scrapeable via raw HTML):
  `forum.openwrt.org/t/questions-about-dell-emc-sd-wan-edge-6x0/128094`.
- AN‑37 SFI regression (6.1+): netdev, commit `565736048bd5`.
- FreeBSD MDIO exposure patch (for the 88E6190 RJ45 ports): `D50128`.
- OPNsense SMBus-enable: `github.com/opnsense/plugins/issues/5556`.
- Dell FCLF8521P2BTL spec: "1G SFP, 1000Base‑T 100 m, Copper RJ‑45".