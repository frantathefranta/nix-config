{ lib, inputs, ... }:
{
  imports = [
    inputs.hardware.nixosModules.common-cpu-intel
    inputs.hardware.nixosModules.common-pc-ssd
    ./services
    ./hardware-configuration.nix

    ../common/global
    ../common/users/fbartik

    ../common/optional/smartd.nix
  ];
  networking = {
    hostName = "qotom";
    useDHCP = false;
    enableIPv6 = true;
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
  networking.nameservers = [];

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
  systemd.network.netdevs."10-dummy42" = {
    netdevConfig = {
      Name = "dummy42";
      Kind = "dummy";
    };
  };
  systemd.network.networks."10-dummy42" = {
    matchConfig.Name = "dummy42";
    address = [
      "fdb7:c21f:f30f:10::10/128"
    ];
    networkConfig = {
      LinkLocalAddressing = false;
      IPv6LinkLocalAddressGenerationMode = "none";
    };
  };
  services.frr = {
    bgpd.enable = true;
    config = ''
      router bgp 65032
        no bgp ebgp-requires-policy
        bgp router-id 10.32.10.10
        neighbor 2600:1702:6630:3fed::1 remote-as 65033
        address-family ipv6
          network fdb7:c21f:f30f:10::10/128 
          neighbor 2600:1702:6630:3fed::1 activate
      ipv6 prefix-list dn42_ips seq 10 permit fd00::/8 ge 48
      route-map correct_src permit 1
        match ipv6 address prefix-list dn42_ips
        set src fdb7:c21f:f30f:10::10
      ipv6 protocol bgp route-map correct_src
    '';
  };
  services.prometheus.exporters.node = {
    listenAddress = "10.32.10.10";
  };
  system.stateVersion = "24.11";
}
