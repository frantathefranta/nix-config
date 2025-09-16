{ inputs, ... }:

{
  imports = [
    inputs.disko.nixosModules.disko
  ];
  boot.kernelModules = [ "kvm-intel" ];
  #boot.extraModulePackages = [ ];
  boot.growPartition = true;
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.availableKernelModules = [
    "uhci_hcd"
    "ahci"
    "xhci_pci"
    "nvme"
    "usbhid"
    "sr_mod"
  ];
  # VMware, Parallels both only support this being 0 otherwise you see
  # "error switching console mode" on boot.
  boot.loader.systemd-boot.consoleMode = "0";
  disko.devices.disk.main = {
    device = "/dev/sda";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        boot = {
          size = "1M";
          type = "EF02"; # for grub MBR
        };
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };

  nixpkgs.hostPlatform.system = "aarch64-linux";
}
