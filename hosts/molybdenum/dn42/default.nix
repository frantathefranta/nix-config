{
  config,
  dn42Of,
  ...
}:
{
  imports = [
    # ./wireguard.nix
    ./bind.nix
    ./caddy.nix
    ./peers/wireguard.nix
  ];

  meta.dn42.host = {
    ipv4 = "172.23.234.17";
    ipv4PrefixLength = 32;
    ipv6Subnet = "0000";
    ipv6Suffix = ":1";
  };
  meta.dn42.region = 42;
  meta.dn42.country = 840;

  # iBGP to nix-hetzner runs over OSPF-routed loopback path (via ibgp_pdx multi-peer tunnel).
  # There is no dedicated WG interface for it, so it cannot be auto-generated from ibgp_* interfaces.
  meta.dn42.extraBirdConfig = ''
    protocol direct dn42_extra {
        interface "dummy53", "ens18.2000", "wg_home";
        ipv4;
        ipv6;
    }
    protocol bgp qotom
     {
      local as 4242421033;
      neighbor fe80::6:5032:1033%wg_qotom as 65032;
      ipv4 {
        extended next hop on;
        import none;
        export filter {
          # export all valid routes
          if ( is_valid_network() && source ~ [ RTS_STATIC, RTS_BGP ] )
          then {
            accept;
          }
          reject;
        };
      };

      ipv6 {
        extended next hop on;
        import filter {
          if ( is_loopback_v6() && source ~ [ RTS_STATIC, RTS_BGP ] )
          then {
            accept;
          }
          reject;
        };
        export filter {
          # export all valid routes
          if ( is_valid_network_v6() && source ~ [ RTS_STATIC, RTS_BGP ] )
          then {
            accept;
          }
          reject;
        };
      };
    }
    protocol bgp arista
     {
      local as 4242421033;
      neighbor fe80::464c:a8ff:fede:3cf7%ens18 as 65033;

      ipv4 {
        # import/export filters
        import none;
        export filter {
          # export all valid routes
          if ( is_self_net() && source ~ [ RTS_STATIC, RTS_BGP ] )
          then {
            accept;
          }
          reject;
        };
      };

      ipv6 {
        # import/export filters
        import filter {
          if ( is_loopback_v6() && source ~ [ RTS_STATIC, RTS_BGP ] )
          then {
            accept;
          }
          reject;
        };
        export filter {
          # export all valid routes
          if ( is_valid_network_v6() && source ~ [ RTS_STATIC, RTS_BGP ] )
          then {
            accept;
          }
          reject;
        };
      };
    }
  '';

  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  networking.nftables.firewall = {
    zones.dns = {
      ipv4Addresses = [ "172.23.234.30/32" ];
      ipv6Addresses = [ "fdb7:c21f:f30f:53::/128" ];
    };
    rules.dns_allow = {
      from = [ "dn42_subnets" ];
      to = [ "dns" ];
      allowedUDPPorts = [ 53 ];
      allowedTCPPorts = [ 53 ];
    };
  };
  systemd.network.netdevs."10-dummy53" = {
    netdevConfig = {
      Name = "dummy53";
      Kind = "dummy";
    };
  };
  systemd.network.networks."10-dummy53" = {
    matchConfig.Name = "dummy53";
    address = [
      "172.23.234.30/32"
      "fdb7:c21f:f30f:53::/128"
    ];
    networkConfig = {
      LinkLocalAddressing = false;
      DNS = "fdb7:c21f:f30f:53::";
      DNSDefaultRoute = false;
    };
    domains = [
      "~dn42"
      "~20.172.in-addr.arpa"
      "~21.172.in-addr.arpa"
      "~22.172.in-addr.arpa"
      "~23.172.in-addr.arpa"
      "~10.in-addr.arpa"
      "~d.f.ip6.arpa"
    ];
  };

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
  systemd.network.netdevs = {
    "20-ens18.2000" = {
      netdevConfig = {
        Name = "ens18.2000";
        Description = "DN42 DHCP";
        Kind = "vlan";
      };
      vlanConfig.Id = 2000;
    };
  };
  systemd.network.networks = {
    "20-ens18.2000" = {
      matchConfig.Name = "ens18.2000";
      networkConfig = {
        IPv6AcceptRA = false;
        IPv6SendRA = true;
        IPv6PrivacyExtensions = false;
      };
      ipv6SendRAConfig = {
        RouterLifetimeSec = 0;
        DNS = "fdb7:c21f:f30f:53::";
      };
      ipv6Prefixes = [ { Prefix = "fdb7:c21f:f30f:0099::/64"; } ];
      ipv6RoutePrefixes = [ { Route = "fd00::/8"; } ];
      addresses = [ { Address = "fdb7:c21f:f30f:0099:172:23:234:17/64"; } ];
      domains = [
        "~dn42"
        "~d.f.ip6.arpa"
      ];
    };
  };

  services.bird-lg = {
    proxy = {
      enable = true;
      listenAddresses = "0.0.0.0:8000";
      allowedIPs = [
        config.meta.dn42.host.ipv4
        config.meta.dn42.host.resolvedIPv6
        (dn42Of "nix-hetzner").resolvedIPv6
        (dn42Of "nix-vultr").resolvedIPv6
      ];
      birdSocket = "/var/run/bird/bird.ctl";
    };
    frontend = {
      enable = true;
      whois = "whois.dn42";
      netSpecificMode = "dn42";
      servers = [
        "us-cmh"
        "us-pdx"
        "cz-prg"
      ];
      domain = "franta.dn42";
      listenAddresses = [
        "10.32.10.242:5000"
        "[${config.meta.dn42.host.resolvedIPv6}]:5000"
      ];
    };
  };

  services.prometheus.exporters.bird = {
    enable = true;
    openFirewall = false;
    listenAddress = "10.32.10.242";
  };
}
