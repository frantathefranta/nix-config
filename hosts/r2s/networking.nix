{ config, lib, ... }:
{
  networking.useDHCP = false;
  networking = {
    # firewall.interfaces.lo.allowedTCPPorts = [
    #   179
    # ];
    firewall.interfaces.eth0.allowedUDPPorts = [
      179
      3784 # BFD messages
      3785 # BFD messages
    ];
    firewall.interfaces.eth1.allowedUDPPorts = [
      179
      3784 # BFD messages
      3785 # BFD messages
    ];
    # firewall.extraCommands = ''
    #   iptables -A nixos-fw -p 89 -j nixos-fw-accept -m comment --comment "Allow OSPF multicast"
    #   ip6tables -A nixos-fw -p 89 -j nixos-fw-accept -m comment --comment "Allow OSPF multicast"
    # '';
  };

  services.timesyncd = {
    servers = [ "0.nixos.pool.ntp.org" ];
    # fallbackServers are 0.nixos.pool.ntp.org 1.nixos.pool.ntp.org 2.nixos.pool.ntp.org 3.nixos.pool.ntp.org
  };
  systemd.network.enable = true;
  systemd.network.config = {
    networkConfig = {
      ManageForeignRoutingPolicyRules = false;
      # SpeedMeter = true;
      ManageForeignNextHops = false;
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
    address = [
      "10.0.0.200/32"
      "2600:1702:6630:3fec::200/128"
    ];
  };
  systemd.network.networks."11-eth0" = {
    name = "eth0";
    networkConfig = {
      Address = "192.168.15.10/24";
      ConfigureWithoutCarrier = true;
    };
    linkConfig.ActivationPolicy = "always-up";
    routes = [
      {
        Gateway = "192.168.15.1";
        # Metric = 2147483647;
      }
    ];
  };

  systemd.network.networks."11-eth1" = {
    name = "eth1";
    networkConfig = {
      # Address = "10.254.0.65/31";
      ConfigureWithoutCarrier = true;
      DHCP = "no";
    };
    # routes = [
    #   {
    #     Gateway = "10.254.0.64";
    #     Metric = 2147483648;
    #   }
    # ];
    linkConfig.ActivationPolicy = "always-up";
  };
  # systemd.network.netdevs."60-he-ipv6" = {
  #   netdevConfig = {
  #     Name = "he-ipv6";
  #     Kind = "sit";
  #     MTUBytes = "1412";
  #   };
  #   tunnelConfig = {
  #     Local = "91.139.115.41";
  #     Remote = "216.66.86.122";
  #     TTL = 255;
  #   };
  # };

  # systemd.network.networks."60-he-ipv6" = {
  #   matchConfig = { Name = "he-ipv6"; };
  #   networkConfig = {
  #     Address = "2001:470:6e:1e8::2/64";
  #   };
  #   routes = [{
  #     Destination = "2000::/3";
  #     Source = "2001:470:6f:1e8::/64";
  #     Metric = 50;
  #   }];
  # };
  services.frr = {
    bfdd.enable = true;
    bgpd.enable = true;
    # ospfd.enable = true;
    # ospf6d.enable = true;
    config = ''
      router bgp 65412
        bgp router-id 10.0.0.200
        bgp log-neighbor-changes
        no bgp ebgp-requires-policy
        no bgp hard-administrative-reset
        no bgp graceful-restart notification
        no bgp network import-check
        neighbor unnumbered peer-group
        neighbor unnumbered remote-as auto
        neighbor unnumbered capability extended-nexthop
        neighbor fe80::de2c:6eff:fe7e:66d4 peer-group unnumbered
        neighbor fe80::de2c:6eff:fe7e:66d4 interface eth1
        # neighbor fe80::4 peer-group unnumbered
        # neighbor fe80::4 interface eth0
        address-family ipv4 unicast
          network 10.0.0.200/32
        exit-address-family
        address-family ipv6 unicast
          neighbor fe80::de2c:6eff:fe7e:66d4 activate
          # neighbor fe80::4 activate
        exit-address-family
      ip prefix-list loopbacks_ips seq 10 permit 0.0.0.0/0 ge 32
      route-map correct_src permit 1
        set src 10.0.0.200
      ip protocol bgp route-map correct_src
    '';
  };
}
