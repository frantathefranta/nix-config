{
  config,
  lib,
  pkgs,
  ...
}:

{
  services = {
    hostapd = {
      enable = true;
      radios.wlp2s0 = {
        countryCode = "US";
        networks.wlp2s0 = {
          ssid = "qotom";
          authentication = {
            wpaPasswordFile = config.sops.secrets.wpa-password.path;
            mode = "wpa2-sha256";
          };

        };
      };
    };
  };
  sops.secrets.wpa-password = {
    sopsFile = ../secrets.yaml;
  };
}
