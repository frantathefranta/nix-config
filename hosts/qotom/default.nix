{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.hardware.nixosModules.common-cpu-intel
    inputs.hardware.nixosModules.common-pc-ssd
    inputs.gobgp.nixosModules.gobgp
    ./services
    ./hardware-configuration.nix

    ../common/global
    ../common/users/fbartik

    ../common/optional/dn42.nix
    ../common/optional/smartd.nix
  ];
  networking = {
    hostName = "qotom";
    useDHCP = false;
    enableIPv6 = true;
    interfaces.lo = {
      ipv4.addresses = [
        {
          address = "10.0.10.10";
          prefixLength = 32;
        }
      ];
      ipv6.addresses = [
        {
          address = "2600:1702:6630:3fec::10:10";
          prefixLength = 128;
        }
      ];
    };
    interfaces.enp1s0 = {
      ipv4.addresses = [
        {
          address = "10.32.10.10";
          prefixLength = 24;
        }
      ];
      ipv6.addresses = [
        {
          address = "2600:1702:6630:3fed:10:32:10:10";
          prefixLength = 64;
        }
      ];
    };
    interfaces.wlp2s0.ipv4 = {
      addresses = [
        {
          address = "172.32.254.1";
          prefixLength = 27;
        }
      ];
    };
    defaultGateway = {
      address = "10.32.10.254";
      interface = "enp1s0";
    };
    defaultGateway6 = {
      address = "fe80::464c:a8ff:fede:3cf7";
      interface = "enp1s0";
    };
    firewall = {
      checkReversePath = false;
      extraCommands = ''
        ${pkgs.iptables}/bin/iptables -A INPUT -s 10.33.00.0/16 -j ACCEPT
        ${pkgs.iptables}/bin/iptables -A INPUT -s 10.32.10.0/24 -j ACCEPT
        ${pkgs.iptables}/bin/iptables -A INPUT -s 172.20.0.0/14 -j ACCEPT
        ${pkgs.iptables}/bin/ip6tables -A INPUT -s fd00::/8 -j ACCEPT
        ${pkgs.iptables}/bin/ip6tables -A INPUT -s fe80::/64 -j ACCEPT
      '';
    };
  };
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.rp_filter" = 0;
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv4.conf.default.rp_filter" = 0;
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };
  # systemd-resolved binds to same IP as dnsmasq, this disables it
  services.resolved.extraConfig = ''
    DNSStubListener=no
  '';

  # The networking.nameservers get prepended to /etc/resolv.conf, defeating the purpose of selecting a DNS server per domain
  networking.nameservers = [ ];

  services.dnsmasq = {
    enable = true;
    resolveLocalQueries = true;
    settings = {
      server = [
        "/dn42/fdb7:c21f:f30f:53::"
        "/d.f.ip6.arpa/fdb7:c21f:f30f:53::"
        "10.33.10.0"
        "10.33.10.1"
      ];
    };
  };
  systemd.network.enable = true;
  systemd.network.netdevs."20-vrf_dn42" = {
    netdevConfig = {
      Name = "dn42";
      Kind = "vrf";
    };
    vrfConfig = {
      Table = 4242;
    };
  };
  systemd.network.netdevs."30-dummy42" = {
    netdevConfig = {
      Name = "dummy42";
      Kind = "dummy";
    };
  };
  systemd.network.networks."30-dummy42" = {
    matchConfig.Name = "dummy42";
    address = [
      "fdb7:c21f:f30f:10::10/128"
    ];
    networkConfig = {
      LinkLocalAddressing = false;
      IPv6LinkLocalAddressGenerationMode = "none";
      VRF = "dn42";
    };
  };
<<<<<<< HEAD
  systemd.services.systemd-networkd.serviceConfig = {
    LoadCredential = [
      "network.wireguard.private.50-wg_mikrotik:${config.sops.secrets."wireguard/mikrotik-private-key".path}"
    ];
  };
  systemd.network.netdevs."50-wg_mikrotik" = {
    netdevConfig = {
      Name = "wg_mikrotik";
      Kind = "wireguard";
    };
    wireguardConfig = {
      PrivateKey = "@network.wireguard.private.50-wg_mikrotik";
      ListenPort = 44069;
    };
    wireguardPeers = [
      {
        Endpoint = "10.32.10.108:44068";
        PersistentKeepalive = 5;
        PublicKey = "E/zt3wlE3yKum2CBlakSCUXGTTLZOoI4giAlKOCk0mY=";
        AllowedIPs = [
          "0.0.0.0/0"
          "::/0"
        ];
      }
    ];
  };
  systemd.network.networks."50-wg_mikrotik" = {
    matchConfig.Name = "wg_mikrotik";
    addresses = [
      {
        Address = "169.254.1.1/16";
        Peer = "169.254.1.2/16";
      }
    ];
    networkConfig = {
      LinkLocalAddressing = false;
    };
  };  sops.secrets = {
    "wireguard/mikrotik-private-key" = {
      sopsFile = ./secrets.yaml;
    };
  };
  services.frr = {
    bgpd.enable = true;
=======
  services.custom-wireguard.interfaces = {
    "50-wg_mikrotik" = {
      listenPort = 44069;
      peerEndpoint = "mikrotik.eu.franta.us:44068";
      peerPublicKey = "E/zt3wlE3yKum2CBlakSCUXGTTLZOoI4giAlKOCk0mY=";
      localAddressV6 = "fe80::aaaa:1/64";
      peerAddressV6 = "fe80::aaaa:2/64";
    };
    "50-wg_molybdenum" = {
      listenPort = 40001;
      peerEndpoint = "molybdenum.infra.franta.us:40001";
      peerPublicKey = "NFfWiBeN7shLWNQOtl8rAvBp36gbqLZu+MeDVCGyMg4=";
      localAddressV6 = "fe80::6:5032:1033/64";
      peerAddressV6 = "fe80::1033:6:5032";
      vrf = "dn42";
    };
  };
  # services.gobgpd = {
  #   enable = true;
  #   zebra = true;
  #   validateConfig = false;
  #   config = {
  #     global = {
  #       as = 65032;
  #       router-id = "10.0.10.10";
  #       # apply-policy.default-import-policy = "reject-route";
  #         apply-policy.import-policy-list = [
  #           "allow-dn42"
  #         ];
  #     };
  #     neighbors = {
  #       "arista" = {
  #         peer-as = 65033;
  #         neighbor-address = "fe80::464c:a8ff:fede:3cf7%enp1s0";
  #         afi-safis.ipv4-unicast = { };
  #         afi-safis.ipv6-unicast = { };
  #         # apply-policy.default-import-policy = "reject-route";
  #         apply-policy.import-policy-list = [
  #           "allow-dn42"
  #         ];
  #       };
  #     };
  #     defined-sets = {
  #       prefix-sets = {
  #         "dn42" = {
  #           prefix-list = [
  #             {
  #               ip-prefix = "fd00::/8";
  #               masklength-range = "48..128";
  #             }
  #           ];
  #         };
  #       };
  #     };
  #     policy-definitions = {
  #       "allow-dn42" = {
  #         statements = {
  #           "match-prefix-set" = {
  #             actions.route-disposition = "accept-route";
  #             conditions = {
  #               match-prefix-set = {
  #                 prefix-set = "dn42";
  #                 match-set-options = "any";
  #               };
  #             };
  #           };
  #         };
  #       };
  #     };
  #   };
  # };
  # services.frr = {
  #   bgpd.enable = true;
  #   config = ''
  #     router bgp 65032
  #       no bgp ebgp-requires-policy
  #       no bgp network import-check
  #       bgp router-id 10.32.10.10
  #       neighbor 2600:1702:6630:3fed::1 remote-as 65033
  #       neighbor fe80::aaaa:2 remote-as 65534
  #       neighbor fe80::aaaa:2 description mikrotik
  #       neighbor fe80::aaaa:2 interface wg_mikrotik
  #       neighbor fe80::aaaa:2 capability extended-nexthop
  #       address-family ipv4 unicast
  #         network 10.0.10.10/32
  #       address-family ipv6
  #         network fdb7:c21f:f30f:10::10/128
  #         network 2600:1702:6630:3fec::10:10/128
  #         neighbor 2600:1702:6630:3fed::1 activate
  #         neighbor 2600:1702:6630:3fed::1 route-map correct_src in
  #         neighbor fe80::aaaa:2 activate
  #         neighbor fe80::aaaa:2 route-map to_mikrotik out
  #     ipv6 prefix-list dn42_ips seq 10 permit fd00::/8 ge 48
  #     ipv6 prefix-list loopback_ips seq 10 permit 2600:1702:6630:3fec::10:10/128
  #     route-map to_mikrotik deny 1
  #       match ipv6 address prefix-list dn42_ips
  #     route-map to_mikrotik permit 2
  #       match ipv6 address prefix-list loopback_ips
  #     route-map correct_src permit 1
  #       match ipv6 address prefix-list dn42_ips
  #       set src fdb7:c21f:f30f:10::10
  #   '';
  # };
  services.bird = {
    enable = true;
>>>>>>> gobgp-qotom
    config = ''
      router id 10.0.10.10;
      protocol device {
          scan time 10;
      }
     ipv4 table DN42v4;
     ipv6 table DN42v6;
     protocol static S_VRF_DN42v6 {
       vrf "dn42";
       route fdb7:c21f:f30f:10::10/128 reject;
       ipv6 { table DN42v6; };
     }
     protocol kernel K_VRF_DN42v4 {
       vrf "dn42";
       kernel table 4242;
       ipv4 {
         table DN42v4;
         export all;
       };
     }
     protocol kernel K_VRF_DN42v6 {
       vrf "dn42";
       kernel table 4242;
       ipv6 {
         table DN42v6;
          export filter {
              if source = RTS_STATIC then reject;
              krt_prefsrc = fdb7:c21f:f30f:10::10;
              accept;
          };
       };
     }
    function is_loopback_v6() {
      return net ~ [
        fd00::/8{128,128}
      ];
    }
     protocol bgp molybdenum {
       local as 65032;
       neighbor fe80::1033:6:5032%wg_molybdenum as 4242421033;
       ipv4 {
         extended next hop on;
         table DN42v4;
         import all;
         export none;
       };
       ipv6 {
         extended next hop on;
         table DN42v6;
         import all;
         export filter {
           if ( is_loopback_v6() ) 
           then {
             accept;
           }
         reject;
         };
       };
       vrf "dn42";
     }
    '';
  };
  services.prometheus.exporters.node = {
    listenAddress = "10.32.10.10";
  };
  system.stateVersion = "24.11";
}
