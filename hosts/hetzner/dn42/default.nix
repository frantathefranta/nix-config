{
  config,
  pkgs,
  ...
}:

{
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.rp_filter" = 0;
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv4.conf.default.rp_filter" = 0;
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };
  environment.systemPackages = [ pkgs.wireguard-tools ];
  systemd.services.systemd-networkd.serviceConfig = {
    LoadCredential = [
      "network.wireguard.private.420-wg4242421033:${
        config.sops.secrets."wireguard/home-private-key".path
      }"
    ];
  };
  systemd.network.netdevs."420-wg4242421033" = {
    netdevConfig = {
      Name = "wg4242421033";
      Kind = "wireguard";
    };
    wireguardConfig = {
      PrivateKey = "@network.wireguard.private.420-wg4242421033";
      ListenPort = 21033;
    };
    wireguardPeers = [
      {
        Endpoint = "cmh.dn42.franta.us:21033";
        PersistentKeepalive = 5;
        PublicKey = "3GAUz/+Q81eblrA78/LfkLs4X2CAsfnIHgw0R8LT9GE=";
        AllowedIPs = [
          "0.0.0.0/0"
          "::/0"
        ];
      }
    ];
  };
  systemd.network.networks."420-wg4242421033" = {
    matchConfig.Name = "wg4242421033";
    addresses = [
      {
        Address = "fe80::1:1033/64";
        Peer = "fe80::1033/64";
      }
    ];
    networkConfig = {
      LinkLocalAddressing = false;
    };
  };
  sops.secrets = {
    "wireguard/home-private-key" = {
      sopsFile = ../secrets.yaml;
      mode = "0640";
      owner = "systemd-network";
      group = "systemd-network";
    };
  };
}
