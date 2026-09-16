# Dell Edge 610 (VEP1400) — SFP / DSA notes

Reference runbook for the diagnostic ISO. The live script is `edge610-diag`
(see `edge610-diag.sh`); this file is background + decision tree.

## Topology

Four Intel X553 backplane functions, all `ixgbe`:

| BDF        | Subsys | Role                                            |
|------------|--------|-------------------------------------------------|
| 03:00.0/.1 | 0x0000 | CPU uplinks **into** the on-board 88E6190 switch (6 RJ45 behind it) |
| 05:00.0/.1 | 0x15c4 | The two **SFP** cages — direct, NOT behind the switch |

Implication: the SFP ports do **not** need DSA to work. DSA (88E6190) is only
required to expose the 6 RJ45 ports.

## Why the SFP works in DiagOS but not stock Linux

Two live hypotheses — `ethtool -m <sfp-if>` on the SFP port is the divider:

- **H1 — cage held off.** The SFP TX line / PHY enable is released by vendor
  I2C/SMBus init that DiagOS runs. Stock Linux never does it → transceiver
  unreadable. Fix: replay the vendor i2c sequence in a systemd unit.
  *Signal:* `ethtool -m` fails to detect the module.

- **H2 — 6.1+ ixgbe AN-37 SFI regression.** Commit `565736048bd5`
  ("ixgbe: Manual AN-37 for troublesome link partners for X550 SFI") changed
  `ixgbe_setup_sfi_x550a()` autoneg handling. Documented to break X553 SFP links
  on kernel ≥ 6.1 (worked on ≤ 5.10). *Signal:* `ethtool -m` reads the module
  fine, but carrier stays 0 on 6.1+ and comes up on 5.10.

This ISO ships **`linuxPackages_5_10`** on purpose: SFP up here ⇒ H2 (and you
have a working stopgap kernel). SFP still dead here ⇒ H1, go to the i2c section.

## Watchdog (separate from SFP)

The board reboots every ~5 min until the watchdog is disabled.

    i2cset -y 1 0x22 0 0 b      # smbus iSMT bus 1, PIC/CPLD at 0x22

Run via `edge610-diag --watchdog`. (Alternatively flash the VEP1400-X BIOS.)

## 88E6190 DSA (the 6 RJ45 ports) — reality check

Full Linux support is **kernel work, not an ISO toggle**:

1. Stock `ixgbe` does not expose the MDIO bus to the switch (the FreeBSD fix
   added `if_ix_mdio.c` + `ixgbe_mdio.c` for this — see reviews.freebsd.org/D50128).
2. Even with MDIO, DSA needs a **CPU-port → master netdev** mapping, normally
   described in devicetree. There is no x86 DT/ACPI description for this board.

So the RJ45 ports will not appear as usable Linux netdevs from an ISO config
file. The ISO's DSA/MDIO section only confirms the modules are present and the
switch is (not) reachable. A real fix = backport MDIO exposure to ixgbe + a
platform/DT glue describing the 88E6190 CPU ports.

## Useful sources

- STH thread (VEP1400 / Edge 610/620): forums.servethehome.com t/39392
- OPNsense SMBus-enable scripts: github.com/opnsense/plugins/issues/5556
- FreeBSD MDIO patch: reviews.freebsd.org/D50128
- AN-37 regression + X553 SFP: netdev 2024/05/21 (commit 565736048bd5)
- OpenWrt Edge 6x0 thread: forum.openwrt.org t/128094