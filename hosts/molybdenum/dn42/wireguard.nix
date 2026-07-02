{
  config,
  pkgs,
  ...
}:
{
  environment.systemPackages = [ pkgs.wireguard-tools ];
  systemd.services.systemd-networkd.serviceConfig = {
    LoadCredential = [
      "network.wireguard.private.89-ibgp_pdx:${config.sops.secrets."wireguard/hetzner-private-key".path}"
    ];
  };
  systemd.network.netdevs."89-ibgp_pdx" = {
    netdevConfig = {
      Name = "ibgp_pdx";
      Kind = "wireguard";
    };
    wireguardConfig = {
      PrivateKey = "@network.wireguard.private.89-ibgp_pdx";
      ListenPort = 21033;
    };
    wireguardPeers = [
      {
        Endpoint = "pdx.dn42.franta.us:21033";
        PersistentKeepalive = 5;
        PublicKey = "scXOalWiEmQsUqsSOENVUso7omWtNprwMJYotWMgV2I=";
        AllowedIPs = [
          "fe80::1:1033/128"
        ];
      }
      {
        Endpoint = "eu1.dn42.franta.us:24001";
        PersistentKeepalive = 5;
        PublicKey = "5SqQoNhZQuFY93I5Gbfks1xoOqOH4GfeSLkCcJ1v6WY=";
        AllowedIPs = [
          "fe80::300:1033/128"
        ];
      }
    ];
  };
  systemd.network.networks."89-ibgp_pdx" = {
    matchConfig.Name = "ibgp_pdx";
    addresses = [
      {
        Address = "fe80::1033/128";
        Peer = "fe80::1:1033/128";
      }
      {
        Address = "169.254.1.3/16";
        Peer = "169.254.1.2/16";
      }
      {
        Address = "fe80::1033/128";
        Peer = "fe80::300:1033/128";
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
  };
}
