{
  ...
}:

{
  networking = {
    # domain = "home.arpa";
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
    ];
    useDHCP = false;
  };
  systemd.network = {
    enable = true;
    wait-online = {
      anyInterface = false;
      ignoredInterfaces = [
        # "wan0"
        # "wan1"
        "lan1"
        "ctr0"
        "mgmt"
        # "wg0"
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

      # WAN0
      "30-wan0" = {
        matchConfig.Name = "wan0";
        networkConfig.DHCP = "yes";
        linkConfig = {
          MTUBytes = "1500";
          RequiredForOnline = "routable";
        };
      };
      "30-eth6" = {
        matchConfig.Name = "eth6";
        networkConfig = {
          IPv6AcceptRA = false;
        };
        addresses = [
          { Address = "10.32.10.230/24"; }
        ];
      };

      # LAN0
      "30-lan0" = {
        matchConfig.Name = "lan0";
        address = [ "10.0.10.1/24" ];
        networkConfig.ConfigureWithoutCarrier = "yes";
        linkConfig.RequiredForOnline = "no"; # TODO: Change when interface is connected
        # linkConfig.RequiredForOnline = "carrier";
        vlan = [
          "lan0.20" # WIFI
          "lan0.50" # IOT
          # "lan0.200" # SERVER
          # "lan0.250" # GUEST
        ];
      };

      #   # HOME VLAN
      "30-lan0.20" = {
        matchConfig.Name = "lan0.20";
        address = [ "10.0.20.1/24" ];
        networkConfig.ConfigureWithoutCarrier = "yes";
        linkConfig.RequiredForOnline = "no"; # TODO: Change when interface is connected
        # linkConfig.RequiredForOnline = "routable";
      };

      #   # IOT VLAN
      "30-lan0.50" = {
        matchConfig.Name = "lan0.50";
        address = [ "10.0.50.1/24" ];
        networkConfig.ConfigureWithoutCarrier = "yes";
        linkConfig.RequiredForOnline = "no"; # TODO: Change when interface is connected
        # linkConfig.RequiredForOnline = "routable";
      };
    };
  };
}
