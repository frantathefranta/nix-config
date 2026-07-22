{ config, ... }:

{
  systemd.services.systemd-networkd.serviceConfig = {
    LoadCredential = [
      "wg_home_key:${config.sops.secrets."wireguard/50-wg_home".path}"
    ];
  };
  sops.secrets = {
    "wireguard/50-wg_home" = {
      sopsFile = ../secrets.yaml;
    };
  };
  systemd.network.netdevs = {
    "50-wg_home" = {
      netdevConfig = {
        Name = "wg_home";
        Kind = "wireguard";
      };
      wireguardConfig = {
        PrivateKey = "@wg_home_key";
        ListenPort = 51820;
        RouteTable = "main";
      };
      wireguardPeers = [
        {
          PublicKey = "silicHWwttt2Ccq3hrIFXW+utFVzk0AJPkmTU0+ikh0=";
          AllowedIPs = [
            "fdb7:c21f:f30f:98::2/128"
          ];
        }
      ];
    };
  };
  systemd.network.networks = {
    "50_wg_home" = {
      matchConfig.Name = "wg_home";
      addresses = [
        {
          Address = "fdb7:c21f:f30f:98::1/64";
        }
      ];
    };
  };
  networking.firewall.allowedUDPPorts = [ config.systemd.network.netdevs."50-wg_home".wireguardConfig.ListenPort ];
}
