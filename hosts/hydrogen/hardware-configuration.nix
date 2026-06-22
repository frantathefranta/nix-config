{ inputs, ... }:

{
  imports = [
    inputs.disko.nixosModules.disko
  ];
  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
    };
    kernelParams = [
      "console=ttyS0,115200n8"
    ];
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "ahci"
        "nvme"
        "usbhid"
        "usb_storage"
        "sd_mod"
        "tpm_crb"
      ];
    };
    binfmt.emulatedSystems = [ "aarch64-linux" ];
  };
  hardware.i2c.enable = true;
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/disk/by-id/nvme-INTEL_SSDPEKNU512GZ_PHKA228407BV512A";
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
            mountOptions = [ "umask=0077" ];
          };
        };
        luks = {
          size = "100%";
          content = {
            type = "luks";
            name = "crypted";
            settings = {
              allowDiscards = true;
              # keyFile = "/tmp/secret.key";
            };
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ]; # override existing partiion
              subvolumes = {
                "/root" = {
                  mountpoint = "/";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "/nix" = {
                  mountpoint = "/nix";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "/persist" = {
                  mountpoint = "/persist";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "/swap" = {
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                  mountpoint = "/swap";
                  swap.swapfile = {
                    size = "16G";
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
  services = {
    btrfs.autoScrub = {
      enable = true;
      fileSystems = [ "/" ];
    };
  };

  nixpkgs.hostPlatform = "x86_64-linux";
}
