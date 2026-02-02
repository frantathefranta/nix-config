{
  config,
  ...
}:

{
  hardware.bluetooth = {
    enable = true;
  };
  sops.secrets.wireless = {
    sopsFile = ../secrets.yaml;
    neededForUsers = true;
  };

  networking.wireless = {
    enable = true;
    fallbackToWPA2 = false;
    # Declarative
    secretsFile = config.sops.secrets.wireless.path;
    networks = {
      "VPWHBNCHzxLr" = {
        pskRaw = "ext:VPWHBNCHzxLr";
      };
    };
    allowAuxiliaryImperativeNetworks = true;
  };
  # Ensure group exists
  users.groups.network = {};
  systemd.services.wpa_supplicant.preStart = "touch /etc/wpa_supplicant.conf";
}
