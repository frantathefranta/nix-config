{
  config,
  pkgs,
  ...
}:

{
  imports = [
    ./bird.nix
  ];
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.rp_filter" = 0;
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv4.conf.default.rp_filter" = 0;
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };
  networking = {
    firewall = {
      checkReversePath = false;
      extraCommands = ''
        ${pkgs.iptables}/bin/ip6tables -A INPUT -s fd00::/8 -j ACCEPT
        ${pkgs.iptables}/bin/ip6tables -A INPUT -s fe80::/64 -j ACCEPT
      '';
    };
  };
  environment.systemPackages = [ pkgs.wireguard-tools ];
  systemd.services.systemd-networkd.serviceConfig = {
    LoadCredential = [
      "network.wireguard.private.89-ospf_wg:${
        config.sops.secrets."wireguard/home-private-key".path
      }"
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
  systemd.network.networks."89-ospf_wg" = {
    matchConfig.Name = "ospf_wg";
    addresses = [
      {
        Address = "fe80::1:1033/64";
        Peer = "fe80::1033/64";
      }
      { Address = "fdb7:c21f:f30f:ffff::2/64"; }
    ];
    networkConfig = {
      LinkLocalAddressing = false;
    };
  };
  systemd.network.netdevs."10-dummy_ospf" = {
    netdevConfig = {
      Name = "dummy_ospf";
      Kind = "dummy";
    };
  };
  systemd.network.networks."10-dummy_ospf" = {
    matchConfig.Name = "dummy_ospf";
    address = [
      "172.23.234.18"
      "fdb7:c21f:f30f:1::1/128"
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
