{
  lib,
  pkgs,
  config,
  ...
}:

{
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv4.tcp_l3mdev_accept" = 1;
    "net.ipv4.udp_l3mdev_accept" = 1;
  };
  environment.systemPackages = [ pkgs.wireguard-tools ];
  networking = {
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
    ];
    useDHCP = false;
  };
  systemd.services.systemd-networkd.serviceConfig = {
    LoadCredential = [
      "wg_iphone_key:${config.sops.secrets."systemd/wg_iphone_key".path}"
    ];
  };
  sops.secrets = {
    "systemd/wg_iphone_key" = {
      sopsFile = ../secrets.yaml;
    };
  };
  systemd.network = {
    enable = true;
    wait-online = {
      anyInterface = false;
      ignoredInterfaces = [
        "lan1"
        "mgmt"
      ];
    };
    links = {
      # rename all interface names to be easier to identify
      "10-wan0" = {
        matchConfig.Path = "pci-0000:05:00.1";
        linkConfig.Name = "wan0";
      };
      "10-lan0" = {
        matchConfig.Path = "pci-0000:05:00.0";
        linkConfig.Name = "lan0";
      };
      "10-eth6" = {
        matchConfig.Path = "pci-0000:07:00.0";
        linkConfig.Name = "eth6";
      };
      # "10-lan1" = {
      #   matchConfig.Path = "pci-0000:04:00.0";
      #   linkConfig.Name = "lan1";
      # };
    };
    netdevs = {
      "10-mgmt" = {
        netdevConfig = {
          Name = "mgmt";
          Kind = "vrf";
        };
        vrfConfig = {
          Table = 1000;
        };
      };
      # VLANs
      "20-lan0.20" = {
        netdevConfig = {
          Name = "lan0.20";
          Description = "WiFi";
          Kind = "vlan";
        };
        vlanConfig.Id = 20;
      };
      "20-lan0.50" = {
        netdevConfig = {
          Name = "lan0.50";
          Description = "IOT";
          Kind = "vlan";
        };
        vlanConfig.Id = 50;
      };
      "20-lan0.999" = {
        netdevConfig = {
          Name = "lan0.999";
          Description = "Guest";
          Kind = "vlan";
        };
        vlanConfig.Id = 999;
      };
      # Wireguard
      "50-wg_iphone" = {
        netdevConfig = {
          Name = "wg_iphone";
          Kind = "wireguard";
        };
        wireguardConfig = {
          PrivateKey = "@wg_iphone_key";
          ListenPort = 51820;
          RouteTable = "main";
        };
        wireguardPeers = [
          {
            PublicKey = "+gNq5fKQnTGfUD+UAC9AEwu0dTaumh5ciVfu7nKZxHQ=";
            AllowedIPs = [
              "172.16.255.2/32"
              "2600:1702:6630:3fe4::2/128"
            ];
          }
          {
            PublicKey = "EBTQHPKWajPGbCpcsivAcGPlWGDyXst4fd6uu/AO1Ss=";
            AllowedIPs = [
              "172.16.255.3/32"
              "2600:1702:6630:3fe4::3/128"
            ];
          }
        ];
      };
    };
    networks = {
      # Disabled interfaces
      # "30-wan1" = {
      #   matchConfig.Name = "wan1";
      #   networkConfig.ConfigureWithoutCarrier = true;
      #   linkConfig.ActivationPolicy = "always-down";
      # };
      # "30-lan1" = {
      #   matchConfig.Name = "lan1";
      #   networkConfig.ConfigureWithoutCarrier = true;
      #   linkConfig.ActivationPolicy = "always-down";
      # };

      "10-lo" = {
        matchConfig.Name = "lo";
        address = [
          "10.0.0.1/32"
          "2600:1702:6630:3fea::1/128"
        ];
        # Linux doesn't add lo route to main routing table by default
        routes = [
          { Destination = "10.0.0.1/32"; }
        ];
      };
      # WAN0
      "30-wan0" = {
        matchConfig.Name = "wan0";
        networkConfig = {
          DHCP = "yes";
          IPv6AcceptRA = "yes";
          IPv6SendRA = "no";
        };
        linkConfig = {
          MACAddress = "F8:9B:6E:42:02:D2";
          MTUBytes = "1500";
          RequiredForOnline = "routable";
        };
        dhcpV6Config = {
          PrefixDelegationHint = "::/60";
          WithoutRA = "solicit";
          DUIDRawData = "0e:00:01:00:01:2e:4e:47:34:60:be:b4:0c:38:80";
          # SendHostname = false;
          # We don't want an IP from the ISP on this interface
          UseAddress = false;
        };
        ipv6AcceptRAConfig = {
          DHCPv6Client = "always";
          UseDNS = "no";
        };
      };
      "30-mgmt" = {
        matchConfig.Name = "mgmt";
        linkConfig = {
          ActivationPolicy = "up";
          RequiredForOnline = false;
        };
      };
      "30-eth6" = {
        matchConfig.Name = "eth6";
        networkConfig = {
          IPv6AcceptRA = false;
          IPv6PrivacyExtensions = false;
          VRF = "mgmt";
        };
        addresses = [
          { Address = "10.32.10.230/24"; }
          { Address = "2600:1702:6630:3fed:10:32:10:230/64"; }
        ];
      };

      # LAN0
      "30-lan0" = {
        matchConfig.Name = "lan0";
        address = [ "10.0.10.1/24" ];
        networkConfig = {
          DHCPPrefixDelegation = true;
          IPv6AcceptRA = false;
          IPv6SendRA = true;
          IPv6PrivacyExtensions = false;
        };
        dhcpPrefixDelegationConfig = {
          SubnetId = 0;
          Token = "::10:0:10:1";
        };
        linkConfig.RequiredForOnline = "routable";
        vlan = [
          "lan0.20" # WIFI
          "lan0.50" # IOT
          "lan0.999" # GUEST
        ];
      };

      #   # HOME VLAN
      "30-lan0.20" = {
        matchConfig.Name = "lan0.20";
        networkConfig = {
          DHCPPrefixDelegation = true;
          IPv6AcceptRA = false;
          IPv6SendRA = true;
          IPv6PrivacyExtensions = false;
        };
        dhcpPrefixDelegationConfig = {
          SubnetId = 1;
          Token = "::10:0:20:1";
        };
        ipv6SendRAConfig = {
          DNS = "2600:1702:6630:3fe1:10:0:20:1";
        };
        domains = [
          "internal"
          "franta.us"
          "infra.franta.us"
        ];
        address = [ "10.0.20.1/24" ];
        linkConfig.RequiredForOnline = "routable";
      };

      #   # IOT VLAN
      "30-lan0.50" = {
        matchConfig.Name = "lan0.50";
        networkConfig = {
          DHCPPrefixDelegation = true;
          IPv6AcceptRA = false;
          IPv6SendRA = true;
          IPv6PrivacyExtensions = false;
        };
        dhcpPrefixDelegationConfig = {
          SubnetId = 2;
        };
        address = [ "10.0.50.1/24" ];
        linkConfig.RequiredForOnline = "routable";
      };

      "30-lan0.999" = {
        matchConfig.Name = "lan0.999";
        address = [ "10.0.99.1/24" ];
        networkConfig = {
          DHCPPrefixDelegation = true;
          # DHCPServer = true;
          IPv6AcceptRA = false;
          IPv6SendRA = true;
          IPv6PrivacyExtensions = false;
        };
        # dhcpServerConfig = {
        #   PoolOffset = 10;
        #   DNS = "1.1.1.1";
        #   ServerAddress = "10.0.99.1/24";
        #   BindToInterface = true;
        # };
        dhcpPrefixDelegationConfig = {
          SubnetId = 3;
        };
        linkConfig.RequiredForOnline = "routable";
      };

      "50_wg_iphone" = {
        matchConfig.Name = "wg_iphone";
        addresses = [
          {
            Address = "172.16.255.1/24";
          }
          {
            Address = "2600:1702:6630:3fe4::1/64";
          }
        ];
      };
    };
  };
  # Override sshd so it listens in mgmt vrf
  services.prometheus.exporters.node = {
    listenAddress = "0.0.0.0";
    openFirewall = false;
  };
  systemd.services.prometheus-node-exporter = {
    serviceConfig.BindNetworkInterface = "mgmt";
  };
  services.custom-wireguard.interfaces = {
    "50-wg_mikrotik" = {
      listenPort = 41000;
      peerEndpoint = "mikrotik.eu.franta.us:41000";
      peerPublicKey = "BkpNRSaQbXazDzVSfyLGnV6WKdVfiRdyTx9YSPWsNwk=";
      peerAddressV6 = "fe80::1/64";
      localAddressV6 = "fe80::2/64";
    };
  };
  systemd.network.networks."50-wg_mikrotik".linkConfig.RequiredForOnline = false;
}
