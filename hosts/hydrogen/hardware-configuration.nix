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
          };
        };
        root = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [ "-f" ]; # override existing partiion
            subvolumes = {
              "/root" = {
                mountOptions = [ "compress=zstd" ];
                mountpoint = "/";
              };
              "/nix" = {
                mountpoint = "/nix";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
              };
              "/persist" = {
                mountOptions = [ "compress=zstd" ];
                mountpoint = "/persist";
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
  services = {
    btrfs.autoScrub = {
      enable = true;
      fileSystems = [ "/" ];
    };
  };

  nixpkgs.hostPlatform = "x86_64-linux";
}
