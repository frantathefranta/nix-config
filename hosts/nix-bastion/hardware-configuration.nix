{ inputs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    inputs.disko.nixosModules.disko
  ];
  boot.kernelModules = [ "kvm-intel" ];
  #boot.extraModulePackages = [ ];
  boot.growPartition = true;
  boot = {
    loader = {
      grub = {
        enable = true;
        device = "nodev";
        # efiSupport = true;
        # efiInstallAsRemovable = true;
      };
    };
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
    # clear /tmp on boot to get a stateless /tmp directory.
    tmp.cleanOnBoot = true;
  };

  disko.devices.disk.main = {
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
  # fileSystems."/" = {
  #   device = "/dev/disk/by-label/nixos";
  #   fsType = "ext4";
  # };

  # fileSystems."/boot" = {
  #   device = "/dev/disk/by-label/ESP";
  #   fsType = "vfat";
  # };

  nixpkgs.hostPlatform = "x86_64-linux";
}
