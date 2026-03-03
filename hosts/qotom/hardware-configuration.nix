{
  inputs,
  ...
}:
{

  imports = [
    inputs.disko.nixosModules.disko
  ];

  nixpkgs.hostPlatform.system = "x86_64-linux";
  boot = {
    initrd.availableKernelModules = [
      "xhci_pci"
      "ehci_pci"
      "ahci"
      "usbhid"
      "sd_mod"
    ];
    kernelModules = [ "kvm-intel" ];
    kernel.sysctl = {
      "net.ipv4.conf.wlp2s0.forwarding" = 1;
    };
    binfmt.emulatedSystems = [ "aarch64-linux" ];
    loader = {
      systemd-boot = {
        enable = true;
      };
      efi.canTouchEfiVariables = true;
      timeout = 3;
    };
  };

  disko.devices.disk.main = {
    device = "/dev/disk/by-id/ata-LITEON_LMH-256V2M-11_MSATA_256GB_TW02HNG6LOH00794B1FQ";
    type = "disk";
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
        root = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [ "-f" ]; # Override existing partition
            # Subvolumes must set a mountpoint in order to be mounted,
            # unless their parent is mounted
            subvolumes = {
              "/root" = {
                mountOptions = [ "compress=zstd" ];
                mountpoint = "/";
              };
              # Parent is not mounted so the mountpoint must be set
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
            };
          };
        };
      };
    };
  };

}
