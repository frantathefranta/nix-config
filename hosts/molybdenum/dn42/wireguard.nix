{
  config,
  pkgs,
  ...
}:
{
  environment.systemPackages = [ pkgs.wireguard-tools ];
  systemd.services.systemd-networkd.serviceConfig = {
    LoadCredential = [
      "network.wireguard.private.89-ospf_wg:${config.sops.secrets."wireguard/hetzner-private-key".path}"
      "network.wireguard.private.50-wg_radxa-eu:${config.sops.secrets."wireguard/50-wg_radxa-eu".path}"
    ];
  };
  systemd.network.netdevs."89-ospf_wg" = {
    netdevConfig = {
      Name = "ospf_wg";
      Kind = "wireguard";
    };
    wireguardConfig = {
      PrivateKey = "@network.wireguard.private.89-ospf_wg";
      ListenPort = 21033;
    };
    wireguardPeers = [
      {
        Endpoint = "pdx.dn42.franta.us:21033";
        PersistentKeepalive = 5;
        PublicKey = "scXOalWiEmQsUqsSOENVUso7omWtNprwMJYotWMgV2I=";
        AllowedIPs = [
          "0.0.0.0/0"
          "::/0"
        ];
      }
    ];
  };
  systemd.network.networks."89-ospf_wg" = {
    matchConfig.Name = "ospf_wg";
    addresses = [
      {
        Address = "fe80::1033/64";
        Peer = "fe80::1:1033/64";
      }
      {
        Address = "169.254.1.1/16";
        Peer = "169.254.1.2/16";
      }
    ];
    networkConfig = {
      LinkLocalAddressing = false;
    };
  };
  systemd.network.netdevs."50-wg_radxa-eu" = {
    netdevConfig = {
      Name = "wg_radxa-eu";
      Kind = "wireguard";
    };
    wireguardConfig = {
      PrivateKey = "@network.wireguard.private.50-wg_radxa-eu";
      ListenPort = 51820;
    };
    wireguardPeers = [
      {
        Endpoint = "10.32.10.119:51821";
        PersistentKeepalive = 5;
        PublicKey = "Cgseg7RDeS4hDU1L8kj4yfxqvSGC3/l84NkUORz5DRo=";
        AllowedIPs = [
          "0.0.0.0/0"
          "::/0"
        ];
      }
    ];
  };
  systemd.network.networks."50-wg_radxa-eu" = {
    matchConfig.Name = "wg_radxa-eu";
    addresses = [
      {
        Address = "fe80::faaa:1/64";
        Peer = "fe80::faaa:2";
      }
    ];
    networkConfig = {
      LinkLocalAddressing = false;
    };
  };

  sops.secrets = {
    "wireguard/hetzner-private-key" = {
      sopsFile = ../secrets.yaml;
    };
    "wireguard/50-wg_radxa-eu" = {
      sopsFile = ../secrets.yaml;
    };
  };
}
