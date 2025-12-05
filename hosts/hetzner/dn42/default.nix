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
        ${pkgs.iptables}/bin/iptables -A INPUT -s 172.20.0.0/14 -j ACCEPT
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
      "network.wireguard.private.42-wg4242423914:${
        config.sops.secrets."wireguard/kioubit-private-key".path
      }"
      "network.wireguard.private.42-wg4242420207:${
        config.sops.secrets."wireguard/routed-bits-private-key".path
      }"
      "network.wireguard.private.42-wg4242423035:${
        config.sops.secrets."wireguard/larecc-private-key".path
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
      {
        Address = "169.254.1.2/16";
        Peer = "169.254.1.1/16";
      }
    ];
    networkConfig = {
      LinkLocalAddressing = false;
    };
  };
  systemd.network.netdevs."42-wg4242423914" = {
    netdevConfig = {
      Name = "wg4242423914";
      Kind = "wireguard";
    };
    wireguardConfig = {
      PrivateKey = "@network.wireguard.private.42-wg4242423914";
      ListenPort = 23914;
    };
    wireguardPeers = [
      {
        Endpoint = "us3.g-load.eu:21033";
        PersistentKeepalive = 5;
        PublicKey = "sLbzTRr2gfLFb24NPzDOpy8j09Y6zI+a7NkeVMdVSR8=";
        AllowedIPs = [
          "0.0.0.0/0"
          "::/0"
        ];
      }
    ];
  };
  systemd.network.networks."42-wg4242423914" = {
    matchConfig.Name = "wg4242423914";
    addresses = [
      {
        Address = "fe80::ade1/64";
        Peer = "fe80::ade0/64";
      }
    ];
    networkConfig = {
      LinkLocalAddressing = false;
    };
  };
  systemd.network.netdevs."42-wg4242420207" = {
    netdevConfig = {
      Name = "wg4242420207";
      Kind = "wireguard";
    };
    wireguardConfig = {
      PrivateKey = "@network.wireguard.private.42-wg4242420207";
      ListenPort = 20207;
    };
    wireguardPeers = [
      {
        Endpoint = "router.sea1.routedbits.com:51033";
        PersistentKeepalive = 5;
        PublicKey = "/aY73VNAGQ7W+GersZUSO6PqHJV8nWKb12Op9EQzY3k=";
        AllowedIPs = [
          "0.0.0.0/0"
          "::/0"
        ];
      }
    ];
  };
  systemd.network.networks."42-wg4242420207" = {
    matchConfig.Name = "wg4242420207";
    addresses = [
      {
        Address = "fe80::1033/64";
        Peer = "fe80::0207/64";
      }
    ];
    networkConfig = {
      LinkLocalAddressing = false;
    };
  };
  systemd.network.netdevs."42-wg4242423035" = {
    netdevConfig = {
      Name = "wg4242423035";
      Kind = "wireguard";
    };
    wireguardConfig = {
      PrivateKey = "@network.wireguard.private.42-wg4242423035";
      ListenPort = 23035;
    };
    wireguardPeers = [
      {
        Endpoint = "usw1.dn42.lare.cc:21033";
        PersistentKeepalive = 5;
        PublicKey = "Qd2XCotubH4QrQIdTZjYG4tFs57DqN7jawO9vGz+XWM=";
        AllowedIPs = [
          "0.0.0.0/0"
          "::/0"
        ];
      }
    ];
  };
  systemd.network.networks."42-wg4242423035" = {
    matchConfig.Name = "wg4242423035";
    addresses = [
      {
        Address = "fe80::1033:3035/64";
        Peer = "fe80::3035:132";
      }
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
    };
    "wireguard/kioubit-private-key" = {
      sopsFile = ../secrets.yaml;
    };
    "wireguard/routed-bits-private-key" = {
      sopsFile = ../secrets.yaml;
    };
    "wireguard/larecc-private-key" = {
      sopsFile = ../secrets.yaml;
    };
  };
}
