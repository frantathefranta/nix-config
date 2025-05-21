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
          ignoreBroadcastSsid = "empty"; # Hides the SSID
          authentication = {
            wpaPasswordFile = config.sops.secrets.wpa-password.path;
            mode = "wpa2-sha256";
          };

        };
      };
    };
    kea.dhcp4 = {
      enable = true;
      settings = {
        interfaces-config = {
          interfaces = [
            "wlp2s0"
          ];
        };
        lease-database = {
          name = "/var/lib/kea/dhcp4.leases";
          persist = true;
          type = "memfile";
        };
        rebind-timer = 2000;
        renew-timer = 1000;
        subnet4 = [
          {
            id = 1;
            pools = [
              {
                pool = "172.32.254.16 - 172.32.254.31";
              }
            ];
            subnet = "172.32.254.0/27";
          }
        ];
        valid-lifetime = 4000;
      };
    };
  };

  sops.secrets.wpa-password = {
    sopsFile = ../secrets.yaml;
  };
}
