{ inputs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    inputs.disko.nixosModules.disko
  ];
  boot = {
    loader = {
      grub = {
        enable = true;
        device = "nodev";
        # efiSupport = true;
        # efiInstallAsRemovable = true;
        extraConfig = "
          serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1
          terminal_input serial
          terminal_output serial
        ";
      };
    };
    kernelParams = [ "console=ttyS0,115200n8" ];
    initrd = {
      availableKernelModules = [
        "9p"
        "9pnet_virtio"
        "ata_piix"
        "uhci_hcd"
        "virtio_blk"
        "virtio_mmio"
        "virtio_net"
        "virtio_pci"
        "virtio_scsi"
      ];
      kernelModules = [
        "virtio_balloon"
        "virtio_console"
        "virtio_rng"
      ];
    };
    # TODO: Uncomment when this moves to a physical host
    # initrd.availableKernelModules = [
    #   "xhci_pci"
    #   "ahci"
    #   "nvme"
    #   "usbhid"
    #   "usb_storage"
    #   "sd_mod"
    # ];
  };
  disko.devices = {
    disk = {
      main = {
        device = "/dev/vda";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02"; # for grub MBR
            };
            ESP = {
              type = "EF00";
              size = "1000M";
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
    };
  };
  nixpkgs.hostPlatform = "x86_64-linux";
}
