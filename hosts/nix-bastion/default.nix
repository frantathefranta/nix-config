{ pkgs, ... }:
{
  imports = [
    ./services
    ./hardware-configuration.nix

    ../common/global
    ../common/optional/qemu-guest-agent.nix
    ../common/optional/1password.nix
    ../common/users/fbartik
  ];
  networking = {
    hostName = "nix-bastion";
    useDHCP = false;
    enableIPv6 = true;
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
    };
    defaultGateway6 = {
      address = "fe80::464c:a8ff:fede:3cf7";
      interface = "ens18";
    };
  };
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.rp_filter" = 0;
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv4.conf.default.rp_filter" = 0;
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };
    # hosts = {
    #   "10.33.35.1" = [
    #     "talos-actinium"
    #     "talos-actinium.infra.franta.us"
    #   ];
    #   "10.33.35.2" = [
    #     "talos-thorium"
    #     "talos-thorium.infra.franta.us"
    #   ];
    #   "10.33.35.3" = [
    #     "talos-protactinium"
    #     "talos-protactinium.infra.franta.us"
    #   ];
    #   "10.33.35.21" = [
    #     "talos-g3-mini"
    #     "talos-g3-mini.infra.franta.us"
    #   ];
    #   "10.33.35.22" = [
    #     "talos-n150-01"
    #     "talos-n150-01.infra.franta.us"
    #   ];
    # };
    # extraHosts = ''
    #   10.33.35.1 talos-actinium.infra.franta.us
    #   10.33.35.2 talos-thorium.infra.franta.us
    #   10.33.35.3 talos-actinium.infra.franta.us
    #   10.33.35.21 talos-g3-mini.infra.franta.us
    #   10.33.35.22 talos-n150-01.infra.franta.us
    # '';
  # };
  
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
      "fdb7:c21f:f30f:10::11/128"
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
        bgp log-neighbor-changes
        no bgp ebgp-requires-policy
        no bgp hard-administrative-reset
        no bgp graceful-restart notification
        no bgp network import-check
        bgp router-id 10.32.10.11
        neighbor ens18 arista01
        neighbor ens18 interface v6only remote-as 65033
        neighbor ens18 capability extended-nexthop
        address-family ipv6
          network fdb7:c21f:f30f:10::11/128 
          neighbor ens18 activate
      ipv6 prefix-list dn42_ips seq 10 permit fd00::/8 ge 48
      route-map correct_src permit 1
        match ipv6 address prefix-list dn42_ips
        set src fdb7:c21f:f30f:10::11
      ipv6 protocol bgp route-map correct_src
    '';
  };
  services.prometheus.exporters.node = {
    listenAddress = "10.32.10.11";
  };
  system.stateVersion = "24.11";
}
