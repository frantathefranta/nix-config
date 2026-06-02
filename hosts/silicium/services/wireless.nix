{
  config,
  pkgs,
  ...
}:

{
  hardware.bluetooth = {
    enable = true;
  };
  sops.secrets.wireless = {
    sopsFile = ../secrets.yaml;
    owner = "wpa_supplicant";
    group = "wpa_supplicant";
    # neededForUsers = true;
  };

  networking.wireless = {
    enable = true;
    # Declarative
    secretsFile = config.sops.secrets.wireless.path;
    networks = {
      "VPWHBNCHzxLr" = {
        pskRaw = "ext:VPWHBNCHzxLr";
        authProtocols = [ "WPA-PSK" ];
      };
    };
    allowAuxiliaryImperativeNetworks = false;
  };
  # Ensure group exists
  users.groups.network = { };
}
