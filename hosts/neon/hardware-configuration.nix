{ inputs, pkgs, ... }: {
  imports = [
    inputs.disko.nixosModules.disko
  ];

  hardware.i2c.enable = true;

  # Dell Edge 610 (VEP1400) — SFP ports and fan are driven by the
  # CPLD over i2c; see ../installer-iso/edge610-diag.nix
  # (SFP TX-enable) and modules/nixos/vep14xx-fan-curve.nix.

  disko.devices.disk.main = {
    type = "disk";
    # HYVD128 128GB NVMe (facter: /dev/nvme0n1)
    device = "/dev/disk/by-id/nvme-HYVD128_2026010701025";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          priority = 1;
          name = "ESP";
          start = "1M";
          end = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
          };
        };
        luks = {
          size = "100%";
          name = "luks";
          content = {
            type = "luks";
            name = "crypted";
            settings = {
              allowDiscards = true;
              # scripts/add-host-key.sh deploys the 1Password LUKS key here
              # keyFile = "/tmp/secret.key";
            };
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes = {
                "/rootfs" = {
                  mountpoint = "/";
                };
                "/home" = {
                  mountpoint = "/home";
                };
                "/nix" = {
                  mountpoint = "/nix";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "/swap" = {
                  mountpoint = "/swap";
                  mountOptions = [ "noatime" ];
                  swap.swapfile = {
                    size = "2G";
                    path = "swapfile";
                  };
                };
              };
            };
          };
        };
      };
    };
  };

  systemd.services.edge610-sfp-tx-enable = {
    description = "Clear VEP1400 CPLD SFP TX_DISABLE bits";
    wantedBy = [
      "network-pre.target"
      "multi-user.target"
    ];
    before = [ "network-pre.target" ];
    after = [ "systemd-modules-load.service" ];
    path = [
      pkgs.coreutils
      pkgs.gnugrep
      pkgs.i2c-tools
    ];
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

  services.btrfs.autoScrub = {
    enable = true;
    fileSystems = [ "/" ];
  };

  boot.kernelParams = [ "console=ttyS0,115200n8" ];
  # Filesystems not managed by Disko
  fileSystems = {
    "/home" = {
      # Needed for sops-nix to work properly on reboot
      # see: https://github.com/Mic92/sops-nix/issues/149
      neededForBoot = true;
    };
  };

  nixpkgs.hostPlatform = "x86_64-linux";
}
