{
  inputs,
  ...
}:

{
  imports = [
    inputs.disko.nixosModules.disko
  ];
  boot.initrd.availableKernelModules = [
    "nvme"
    "ehci_pci"
    "xhci_pci_renesas"
    "xhci_pci"
    "usb_storage"
    "sd_mod"
    "rtsx_pci_sdmmc"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.kernelParams = [ "psmouse.proto=imps" ]; # This fixes trackpoint choppiness
  boot.extraModulePackages = [ ];
  boot.loader = {
    systemd-boot = {
      enable = true;
      consoleMode = "max";
    };
    efi.canTouchEfiVariables = true;
  };
  disko.devices.disk.main = {
    device = "/dev/disk/by-id/nvme-WDC_PC_SN720_SDAQNTW-256G-1001_192846427976";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        boot = {
          size = "1M";
          type = "EF02";
        };
        esp = {
          name = "ESP";
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
          };
        };
        luks = {
          size = "100%";
          content = {
            name = "root";
            type = "luks";
            settings.allowDiscards = true;
            passwordFile = "/tmp/secret.key";
            content = {
              type = "btrfs";
              # postCreateHook = ''
              #   MNTPOINT=$(mktemp -d)
              #   mount -t btrfs "$device" "$MNTPOINT"
              #   trap 'umount $MNTPOINT; rm -d $MNTPOINT' EXIT
              #   btrfs subvolume snapshot -r $MNTPOINT/root $MNTPOINT/root-blank
              # '';
              subvolumes = {
                "/root" = {
                  mountOptions = [ "compress=zstd" ];
                  mountpoint = "/";
                };
                "/nix" = {
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                  mountpoint = "/nix";
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
                    size = 16 * 1024;
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

  nixpkgs.hostPlatform = "x86_64-linux";
}
