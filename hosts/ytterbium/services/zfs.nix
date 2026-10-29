{
  boot = {
    supportedFilesystems = {
      zfs = true;
    };
    zfs = {
      forceImportRoot = false;
      extraPools = [ "emc1" ];
      devNodes = "/dev/disk/by-id";
    };
  };

  services.prometheus.exporters.zfs = {
    enable = true;
    openFirewall = true;
  };
}
