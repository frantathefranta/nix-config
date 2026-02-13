let
  lo_ipv6 = "2600:1702:6630:3fec::10:11";
  dn42_ipv6 = "fdb7:c21f:f30f:10::11";
in
{
  imports = [
    ./hardware-configuration.nix

    ../common/global
    ../common/roles/server.nix
    ../common/optional/qemu-guest-agent.nix
    ../common/optional/1password.nix
    ../common/users/fbartik
    ../common/users/admin
    ./services
  ];
  networking = {
    hostName = "nix-bastion";
    useDHCP = false;
    enableIPv6 = true;
    interfaces.lo = {
      ipv4.addresses = [
        {
          address = "10.0.10.11";
          prefixLength = 32;
        }
      ];
      ipv6.addresses = [
        {
          address = lo_ipv6;
          prefixLength = 128;
        }
      ];
    };
    interfaces.ens18 = {
      ipv4.addresses = [
        {
          address = "10.32.10.11";
          prefixLength = 24;
        }
      ];
      ipv6.addresses = [
        {
          address = "2600:1702:6630:3fed:10:32:10:11";
          prefixLength = 64;
        }
      ];
    };
    defaultGateway = {
      address = "10.32.10.254";
      interface = "ens18";
      metric = 2147483647;
    };
    defaultGateway6 = {
      address = "fe80::464c:a8ff:fede:3cf7";
      interface = "ens18";
      metric = 2147483647;
    };
    firewall.interfaces.ens18 = {
      allowedTCPPorts = [
        80
        443
      ];
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

  time.timeZone = "America/Detroit";
  services.dnsmasq = {
    enable = true;
    resolveLocalQueries = true;
    settings = {
      clear-on-reload = true;
      server = [
        "/dn42/fdb7:c21f:f30f:53::"
        "/d.f.ip6.arpa/fdb7:c21f:f30f:53::"
        "10.33.10.0"
        "10.33.10.1"
      ];
    };
  };

  systemd.network.enable = true;
  systemd.network.netdevs."10-dummy42" = {
    netdevConfig = {
      Name = "dummy42";
      Kind = "dummy";
    };
  };
  systemd.network.networks."10-dummy42" = {
    matchConfig.Name = "dummy42";
    address = [
      "${dn42_ipv6}/128"
    ];
    networkConfig = {
      LinkLocalAddressing = false;
      IPv6LinkLocalAddressGenerationMode = "none";
    };
  };
  services.bird = {
    enable = true;
    config = ''
        router id 10.0.10.11;
        protocol device {
            scan time 10;
        }
        protocol direct {
          interface "lo";
          interface "dummy42";
          ipv4;
          ipv6;
        }
        function is_dn42_network_v6() -> bool {
            return net ~ [
                fd00::/8{8,8} 
            ];
        }
        protocol kernel {
            scan time 20;

            ipv6 {
                export filter {
                    if source = RTS_STATIC then reject;
                    if is_dn42_network_v6() then krt_prefsrc = ${dn42_ipv6};
                    # krt_prefsrc = ${lo_ipv6};
                    accept;
                };
            };
        };
        protocol kernel {
            scan time 20;

            ipv4 {
                export filter {
                    if source = RTS_STATIC then reject;
                    krt_prefsrc = 10.0.10.11;
                    accept;
                };
            };
        };
      function is_loopback_v4() -> bool {
        return net ~ [
          10.0.0.0/8{32,32}
        ];
      }
      function is_loopback_v6() -> bool {
        return net ~ [
          ::/0{128,128}
        ];
      }
       protocol bgp mikrotik {
         local fe80::2 as 65032;
         neighbor fe80::1%wg_mikrotik as 65534;
         strict bind yes;
         ipv4 {
           extended next hop on;
           table master4;
           import all;
           export filter {
             if ( is_loopback_v4() ) 
             then {
               accept;
             }
             reject;
           };
         };
         ipv6 {
           extended next hop on;
           table master6;
           import all;
           export none;
           # export filter {
           #   if ( is_loopback_v6() ) 
           #   then {
           #     accept;
           #   }
           # reject;
           # };
         };
         vrf "default";
       }
       protocol bgp arista {
         local fe80::be24:11ff:fe2a:28f1 as 65032;
         neighbor fe80::464c:a8ff:fede:3cf7%ens18 as 65033;
         strict bind yes;
         ipv4 {
           extended next hop on;
           import all;
           import filter {
             if ( is_loopback_v4() ) 
             then {
               accept;
             }
             reject;
           };
           export filter {
             if ( is_loopback_v4() ) 
             then {
               accept;
             }
             reject;
           };
         };
         ipv6 {
           extended next hop on;
           import all;
           export filter {
             if ( is_loopback_v6() ) 
             then {
               accept;
             }
             reject;
           };
         };
        vrf "default";
       }
    '';
  };
  # services.frr = {
  #   bgpd.enable = true;
  #   config = ''
  #     router bgp 65032
  #       bgp log-neighbor-changes
  #       no bgp ebgp-requires-policy
  #       no bgp hard-administrative-reset
  #       no bgp graceful-restart notification
  #       no bgp network import-check
  #       bgp router-id 10.32.10.11
  #       neighbor ens18 description arista01
  #       neighbor ens18 interface v6only remote-as 65033
  #       neighbor ens18 capability extended-nexthop
  #       neighbor fe80::1 remote-as 65534
  #       neighbor fe80::1 description mikrotik
  #       neighbor fe80::1 interface wg_mikrotik
  #       neighbor fe80::1 capability extended-nexthop
  #       neighbor fe80::1 next-hop-self
  #       address-family ipv4
  #         network 10.0.10.11/32
  #       address-family ipv6
  #         network 2600:1702:6630:3fec::10:11/128
  #         network fdb7:c21f:f30f:10::11/128
  #         neighbor ens18 activate
  #         neighbor ens18 route-map correct_src_v6 in
  #         neighbor fe80::1 activate
  #         neighbor fe80::1 route-map advertise_loopbacks out
  #     ip prefix-list loopbacks_ips seq 10 permit 0.0.0.0/0 ge 32
  #     ip prefix-list nix-bastion_ip seq 10 permit 10.0.10.11/32
  #     ipv6 prefix-list dn42_ips seq 10 permit fd00::/8
  #     route-map correct_src_v6 permit 1
  #       match ipv6 address prefix-list dn42_ips
  #       set src fdb7:c21f:f30f:10::11
  #     route-map correct_src_v6 permit 5
  #       set src 2600:1702:6630:3fec::10:11
  #     route-map correct_src_v4 permit 1
  #       set src 10.0.10.11
  #     route-map advertise_loopbacks permit 5
  #       match ip address prefix-list nix-bastion_ip
  #     #ip protocol bgp route-map correct_src_v4
  #     # ipv6 protocol bgp route-map correct_src_v6
  #   '';
  # };
  services.prometheus.exporters.node = {
    listenAddress = "10.32.10.11";
  };
  system.stateVersion = "24.11";
}
