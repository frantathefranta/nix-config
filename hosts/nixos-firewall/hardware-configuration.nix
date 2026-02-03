{ inputs, ... }:

{
  imports = [
    inputs.disko.nixosModules.disko
  ];
  boot = {
    loader = {
      timeout = 1;
      systemd-boot = {
        enable = true;
      };
      efi.canTouchEfiVariables = true;
    };
    kernelParams = [ "console=ttyS0,115200n8" ];
    initrd.availableKernelModules = [
      "xhci_pci"
      "ahci"
      "nvme"
      "usbhid"
      "usb_storage"
      "sd_mod"
    ];
  };
  hardware.i2c.enable = true;
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/disk/by-id/ata-256GB_SATA_Flash_Drive_E02210565000000011ED";
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
        root = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [ "-f" ]; # override existing partiion
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
            };
          };
        };
      };
    };
  };
  services = {
    btrfs.autoScrub = {
      enable = true;
      fileSystems = [ "/" ];
    };
  };

  # filesystems not managed by Disko are defined here
  fileSystems = {
    "/home" = {
      # This is needed for `sops-nix` to work properly on reboot
      # see: https://github.com/Mic92/sops-nix/issues/149
      neededForBoot = true;
    };
  };

  nixpkgs.hostPlatform = "x86_64-linux";
}
