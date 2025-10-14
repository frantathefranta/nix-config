{ config, lib, ... }:
{
  networking.useDHCP = false;
  networking = {
    firewall.interfaces.lo.allowedTCPPorts = [
      179
    ];
    firewall.interfaces.eth0.allowedUDPPorts = [
      3784 # BFD messages
      3785 # BFD messages
    ];
    firewall.interfaces.eth1.allowedUDPPorts = [
      3784 # BFD messages
      3785 # BFD messages
    ];
    firewall.extraCommands = ''
      iptables -A nixos-fw -p 89 -j nixos-fw-accept -m comment --comment "Allow OSPF multicast"
      ip6tables -A nixos-fw -p 89 -j nixos-fw-accept -m comment --comment "Allow OSPF multicast"
    '';
  };

  systemd.network.enable = true;
  systemd.network.config = {
    networkConfig = {
      ManageForeignRoutingPolicyRules = false;
      # SpeedMeter = true;
      # ManageForeignNextHops = false;
      ManageForeignRoutes = false;
    };
  };

  systemd.services."systemd-networkd" = {
    serviceConfig = {
      # avoid infinity restarting,
      # we want to tty into the system as network is not functional
      Restart = "no";
    };
  };
  systemd.network.wait-online = {
    # ignoredInterfaces = [
    #   "tun0"
    #   "eth0"
    #   "eth1"
    # ];
    timeout = 20;
  };

  systemd.network.links."10-eth0" = {
    matchConfig.Path = "platform-ff540000.ethernet";
    linkConfig = {
      Name = "eth0";
      # MACAddress = "fe:1b:f3:16:82:a6";
      # RxBufferSize = 1024;
      # TxBufferSize = 1024;
      TransmitQueueLength = 2000;
      TCPSegmentationOffload = false;
      TCP6SegmentationOffload = false;
    };
  };

  systemd.network.links."10-eth1" = {
    matchConfig.Path = "platform-xhci-hcd.0.auto-usb-0:1:1.0";
    linkConfig = {
      Name = "eth1";
      # MACAddress = "ea:ce:b4:a1:ce:94";
      # RxBufferSize = 4096;
      TransmitQueueLength = 2000;
      TCPSegmentationOffload = false;
      TCP6SegmentationOffload = false;
    };
  };

  systemd.network.networks."10-lo" = {
    matchConfig.Name = "lo";
    address = [ "10.0.0.200/32" ];
  };
  systemd.network.networks."11-eth0" = {
    name = "eth0";
    networkConfig = {
      Address = "10.254.0.63/31";
      ConfigureWithoutCarrier = true;
      # DHCPServer = true;
      # IPv6SendRA = true;
      # DHCPPrefixDelegation = true;
    };
    # dhcpServerConfig = {
    #   PoolOffset = 2;
    #   DefaultLeaseTimeSec = "12h";
    #   MaxLeaseTimeSec = "24h";
    #   UplinkInterface = "extern0";
    #   DNS = [ "_server_address" ];
    # };
    # dhcpPrefixDelegationConfig = {
    #   UplinkInterface = "extern0";
    #   Token = "static:::1";
    # };
    # ipv6SendRAConfig = {
    #   EmitDNS = true;
    #   DNS = [ "_link_local" ];
    # };
    linkConfig.ActivationPolicy = "always-up";
    routes = [
      {
        Gateway = "10.254.0.62";
        Metric = 2147483647;
      }
    ];
  };

  systemd.network.networks."11-eth1" = {
    name = "eth1";
    networkConfig = {
      Address = "10.254.0.65/31";
      ConfigureWithoutCarrier = true;
      DHCP = "yes";
    };
    routes = [
      {
        Gateway = "10.254.0.64";
        Metric = 2147483648;
      }
    ];
    linkConfig.ActivationPolicy = "always-up";
  };
  services.frr = {
    bfdd.enable = true;
    bgpd.enable = true;
    ospfd.enable = true;
    # ospf6d.enable = true;
    config = ''
      # debug ospf event
      # debug ospf zebra
      ${lib.optionalString config.virtualisation.multipass.enable ''
        interface mpqemubr0
          ip ospf prefix-suppression
      ''}
      interface lo
        ip ospf passive
      interface eth0
        ip ospf bfd
      interface eth1
        ip ospf bfd
      router ospf
        ospf router-id 10.0.0.200
        auto-cost reference-bandwidth 200000
        max-metric router-lsa administrative
        network 10.0.0.0/8 area 0.0.0.0
      router bgp 65033
        bgp router-id 10.0.0.200
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
        set src 10.0.0.200
      ip protocol ospf route-map SETSOURCE
    '';
  };
}
