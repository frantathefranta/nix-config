{inputs, ...}: {
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
              keyFile = "/tmp/secret.key";
            };
            content = {
              type = "btrfs";
              extraArgs = ["-f"];
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
                  mountOptions = ["noatime"];
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

  services.btrfs.autoScrub = {
    enable = true;
    fileSystems = ["/"];
  };

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
