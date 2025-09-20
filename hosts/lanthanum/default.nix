{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.hardware.nixosModules.common-cpu-amd
    inputs.hardware.nixosModules.common-pc-ssd
    ./services
    ./hardware-configuration.nix

    ../common/global
    ../common/users/fbartik

    ../common/optional/kde.nix
    ../common/optional/1password.nix
    ../common/optional/fwupd.nix
  ];
  networking = {
    hostName = "lanthanum";
    useDHCP = false;
    # dhcpcd.IPv6rs = true;
    # defaultGateway = {
    #   metric = 2147483648;
    #   address = "10.254.0.1";
    #   interface = "eno1";
    # };
    interfaces = {
      # eno1 = {
      #   mtu = 9000;
      #   ipv4 = {
      #     addresses = [
      #       {
      #         address = "10.254.0.2";
      #         prefixLength = 30;
      #       }
      #     ];
      #     # routes = [
      #   {
      #     address = "0.0.0.0";
      #     prefixLength = 0;
      #     via = "10.254.0.1";
      #   }
      # ];     #
      #   };
      #   ipv6 = {
      #     addresses = [
      #       {
      #         address = "2600:1702:6630:3fec::254:1";
      #         prefixLength = 127;
      #       }
      #     ];
      #     routes = [
      #       {
      #         address = "::";
      #         prefixLength = 0;
      #         via = "2600:1702:6630:3fec::254:0";
      #       }
      #     ];
      #   };
      # };
    };
    # vlans = {
    #   vlan33 = { id=33; interface="eno1"; };
    # };
    # interfaces.vlan33 = {
    #   useDHCP = true;
    # };
    firewall.interfaces.enp1s0.allowedTCPPorts = [
      22000
    ];
    firewall.interfaces.enp1s0.allowedUDPPorts = [
      21027
      22000
    ];
    firewall.extraCommands = ''
      iptables -A nixos-fw -p 89 -j nixos-fw-accept -m comment --comment "Allow OSPF multicast"
      iptables -A nixos-fw -p udp --dport 3784 -j nixos-fw-accept -m comment --comment "Allow BFD messages"
      iptables -A nixos-fw -p udp --dport 3785 -j nixos-fw-accept -m comment --comment "Allow BFD messages"
      ip6tables -A nixos-fw -p 89 -j nixos-fw-accept -m comment --comment "Allow OSPF multicast"
      ip6tables -A nixos-fw -p udp --dport 3784 -j nixos-fw-accept -m comment --comment "Allow BFD messages"
      ip6tables -A nixos-fw -p udp --dport 3785 -j nixos-fw-accept -m comment --comment "Allow BFD messages"
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
    ospfd.enable = true;
    ospf6d.enable = true;
    config = ''
      log syslog
      debug ospf event
      frr defaults datacenter
      interface lo
        ip ospf passive
      interface eno1
        ip ospf area 0.0.0.0
        ip ospf bfd
        ip ospf network point-to-point
        ipv6 ospf6 bfd
        ipv6 ospf6 area 0.0.0.0
        ipv6 ospf6 network point-to-point
        ipv6 ospf6 instance-id 0
      router ospf
        ospf router-id 10.0.0.99
        auto-cost reference-bandwidth 200000
        max-metric router-lsa administrative
        network 10.0.0.0/8 area 0.0.0.0
      router ospf6
        ospf6 router-id 10.0.0.99
      # route-map SETSOURCE permit 10
      #   set src 10.0.0.99
      # ip protocol ospf route-map SETSOURCE
    '';
  };

  programs = {
    dconf.enable = true;
    steam.enable = true;
  };
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware = {
    graphics.enable = true;
    nvidia.modesetting.enable = true;
    nvidia.open = true;
    nvidia.powerManagement.enable = true;
    nvidia.nvidiaPersistenced = true;

    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
    enableAllFirmware = true;
  };
  environment.systemPackages = with pkgs; [
    nvme-cli
    vial
    via
  ];
  services.udev.packages = with pkgs; [
    vial
    via
  ];
  fonts.packages = with pkgs; [
    etBembo
  ];
  system.stateVersion = "24.11";
}
