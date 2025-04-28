{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/profiles/qemu-guest.nix")
    ];

  boot.kernelModules = [ "kvm-intel" ];
  #boot.extraModulePackages = [ ];
  boot.growPartition = true;
  boot = {
    loader = {
      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
        efiInstallAsRemovable = true;
      };
    };
    initrd = {
      availableKernelModules = [ "9p" "9pnet_virtio" "ata_piix" "uhci_hcd" "virtio_blk" "virtio_mmio" "virtio_net" "virtio_pci" "virtio_scsi" ];
      kernelModules = [ "virtio_balloon" "virtio_console" "virtio_rng" ];
    };
    # clear /tmp on boot to get a stateless /tmp directory.
    tmp.cleanOnBoot = true;
  };



  fileSystems."/" =
    { 
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { 
      device = "/dev/disk/by-label/ESP";
      fsType = "vfat";
    };

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  # networking.useDHCP = lib.mkDefault true;
  networking.interfaces.ens18.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}

