{ config, lib, ... }:
{
  networking = {
    firewall.interfaces.eno1.allowedTCPPorts = [
      179
      22000
    ];
    firewall.interfaces.eno1.allowedUDPPorts = [
      21027
      22000
      3784 # BFD messages
      3785 # BFD messages
    ];
    firewall.extraCommands = ''
      iptables -A nixos-fw -p 89 -j nixos-fw-accept -m comment --comment "Allow OSPF multicast"
      ip6tables -A nixos-fw -p 89 -j nixos-fw-accept -m comment --comment "Allow OSPF multicast"
    '';
  };
  systemd.network = {
    enable = true;
    netdevs."50-vxlan200" = {
      netdevConfig = {
        Name = "vxlan200";
        Kind = "vxlan";
      };
      vxlanConfig = {
        VNI = 200;
        Local = "10.0.0.99";
        MacLearning = false;
        Independent = true;
      };
    };
    networks."10-lo" = {
      matchConfig.Name = "lo";
      address = [ "10.0.0.99/32" ];
    };
    networks."10-eno1" = {
      matchConfig.Name = "eno1";
      networkConfig = {
        IPv6AcceptRA = false;
      };
      dns = [
        "10.33.10.0"
        "10.33.10.1"
      ];
      addresses = [
        { Address = "10.254.0.2/30"; }
        {
          Address = "2600:1702:6630:3fec::254:1/127";
          AddPrefixRoute = false;
        }
      ];
      routes = [
        {
          Gateway = "10.254.0.1";
          Metric = 2147483648;
        }
        {
          Gateway = "2600:1702:6630:3fec::254:0";
          GatewayOnLink = "yes";
          Metric = 2147483648;
        }
      ];
      linkConfig.MTUBytes = "9000";
    };
  };
  services.frr = {
    bfdd.enable = true;
    bgpd.enable = true;
    ospfd.enable = true;
    ospf6d.enable = true;
    config = ''
      debug ospf event
      debug ospf zebra
      ${lib.optionalString config.virtualisation.multipass.enable ''
        interface mpqemubr0
          ip ospf prefix-suppression
      ''}
      interface lo
        ip ospf area 0.0.0.0
      interface eno1
        ip ospf area 0.0.0.0
        ip ospf bfd
        ip ospf network point-to-point
        ipv6 ospf6 area 0.0.0.0
        ipv6 ospf6 bfd
        ipv6 ospf6 network point-to-point
      router ospf
        ospf router-id 10.0.0.99
        auto-cost reference-bandwidth 200000
        max-metric router-lsa administrative
      router ospf6
        ospf6 router-id 10.0.0.99
      router bgp 65033
        bgp router-id 10.0.0.99
        bgp log-neighbor-changes
        no bgp ebgp-requires-policy
        no bgp hard-administrative-reset
        no bgp graceful-restart notification
        no bgp network import-check
        neighbor fabric peer-group
        neighbor fabric update-source lo
        neighbor 10.0.0.2 remote-as 65033
        neighbor 10.0.0.2 peer-group fabric
      route-map SETSOURCE permit 10
        set src 10.0.0.99
      ip protocol ospf route-map SETSOURCE
    '';
  };
}
