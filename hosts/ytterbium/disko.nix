{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/disk/by-id/ata-ADATA_SU635_2K43291DN11D";
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
}
