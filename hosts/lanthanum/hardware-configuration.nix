{ inputs, config, ... }:

{
  imports = [
    inputs.disko.nixosModules.disko
  ];

  # Use the systemd-boot EFI boot loader.
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 3;
      };
      efi.canTouchEfiVariables = true;
    };
    initrd.availableKernelModules = [
      "xhci_pci"
      "ahci"
      "nvme"
      "usbhid"
      "usb_storage"
      "sd_mod"
    ];
    kernelModules = [
      "uinput"
      "kvm-amd"
      "8852bu"
    ];
    extraModprobeConfig = ''
      options nvidia_modeset vblank_sem_control=0 nvidia NVreg_PreserveVideoMemoryAllocations=1 NVreg_TemporaryFilePath=/var/tmp
    '';
    extraModulePackages = with config.boot.kernelPackages; [ rtl8852bu ];
    # clear /tmp on boot to get a stateless /tmp directory.
    tmp.cleanOnBoot = true;
    supportedFilesystems = [ "nfs" ];
  };
  disko.devices = {
    disk = {
      main = {
        device = "/dev/disk/by-id/nvme-PCIe_SSD_25031320800278";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            MBR = {
              priority = 0;
              size = "1M";
              type = "EF02";
            };
            ESP = {
              type = "EF00";
              size = "1000M";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
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
      secondary = {

        device = "/dev/disk/by-id/nvme-Dell_Express_Flash_NVMe_P4510_4TB_SFF_PHLJ030201EM4P0DGN";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/nvme";
              };
            };
          };
        };
      };
    };
  };
  fileSystems."/mnt/music" = { # TODO: This should probably be a global optional option
    device = "actinium-nfs.infra.franta.us:/emc1/music";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" ];
  };

  nixpkgs.hostPlatform = "x86_64-linux";
}
