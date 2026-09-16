{
  lib,
  pkgs,
  ...
}:

{
  /*
    Dell Edge 610 (VEP1400) SFP initialization.

    The VEP1400 CPLD boots with bit 7 (TX_DISABLE) set in its SFP control
    registers. Dell DiagOS /etc/rc.local clears both bits after ixgbe probes:

      i2cset -y 1 0x31 0x10 0x00 b
      i2cset -y 1 0x31 0x11 0x00 b

    DiagOS calls its iSMT adapter bus 1; NixOS normally calls the same adapter
    bus 0. The service below finds the adapter by name rather than assuming a
    number. This was verified live: clearing the bits changed eno4 from
    NO-CARRIER to a 1G full-duplex link with the same SFP/cable/partner.

    5.10 remains useful as the pre-AN-37 SFI-regression reference kernel.
  */
  boot.kernelModules = [ "i2c-dev" "i2c-ismt" ];

  systemd.services.edge610-sfp-tx-enable = {
    description = "Clear VEP1400 CPLD SFP TX_DISABLE bits";
    wantedBy = [ "network-pre.target" "multi-user.target" ];
    before = [ "network-pre.target" ];
    after = [ "systemd-modules-load.service" ];
    path = [ pkgs.coreutils pkgs.gnugrep pkgs.i2c-tools ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -euo pipefail
      bus=""

      # Wait briefly for the iSMT PCI function and identify its dynamic bus ID.
      # Linux 6.18 removed /sys/class/i2c-adapter; older kernels still expose it.
      for _ in $(seq 1 10); do
        for adapter in /sys/bus/i2c/devices/i2c-* /sys/class/i2c-adapter/i2c-*; do
          [ -r "$adapter/name" ] || continue
          if grep -qx "SMBus iSMT adapter at dff3c000" "$adapter/name"; then
            bus="''${adapter##*/i2c-}"
            break 2
          fi
        done
        sleep 1
      done

      [ -n "$bus" ] || {
        echo "VEP1400 iSMT adapter was not found" >&2
        exit 1
      }

      # Exact Dell DiagOS rc.local SFP TX-enable sequence. Do not PCI-rescan.
      i2cset -y "$bus" 0x31 0x10 0x00 b
      i2cset -y "$bus" 0x31 0x11 0x00 b

      for reg in 0x10 0x11; do
        value="$(i2cget -y "$bus" 0x31 "$reg")"
        if (( value & 0x80 )); then
          echo "VEP1400 SFP TX_DISABLE remains set: reg $reg = $value" >&2
          exit 1
        fi
      done
    '';
  };

  environment.systemPackages = with pkgs; [
    ethtool        # the H1/H2 divider: `ethtool -m <sfp-if>` reads the SFP EEPROM
    i2c-tools      # i2cdetect / i2cdump / i2cset  (watchdog + SFP/switch exploration)
    pciutils       # lspci
    net-tools      # ifconfig (quick carrier check)
    iputils        # ping
    iperf3         # throughput once a port is up
    lm_sensors     # sensors (fan/CPU temp)
    smartmontools  # eMMC/SSD health
    (
      pkgs.writeShellScriptBin "edge610-diag" (
        builtins.readFile ./edge610-diag.sh
      )
    )
  ];

  # Human-readable runbook on the serial console: /etc/edge610-runbook.md
  environment.etc."edge610-runbook.md".source = ./edge610-notes.md;
}
