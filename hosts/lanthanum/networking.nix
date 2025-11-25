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
  networking.wireless = {
    enable = true;
    # Imperative
    allowAuxiliaryImperativeNetworks = true;
    extraConfig = ''
      ctrl_interface=DIR=/run/wpa_supplicant GROUP=${config.users.groups.network.name}
      update_config=1
    '';
  };
  # Ensure group exists
  users.groups.network = { };
  systemd.network = {
    enable = true;
    networks."10-lo" = {
      matchConfig.Name = "lo";
      address = [ "10.0.0.99/32" ];
    };
    networks."10-eno1" = {
      matchConfig.Name = "eno1";
      networkConfig = {
        IPv6AcceptRA = false;
      };
      # dns = [
      #   "10.33.10.0"
      #   "10.33.10.1"
      # ];
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
          Gateway = "fe80::464c:a8ff:fede:3cf7";
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
      ${lib.optionalString config.virtualisation.multipass.enable ''
        interface mpqemubr0
          ip ospf prefix-suppression
      ''}
      router bgp 65033
        bgp router-id 10.0.0.99
        bgp log-neighbor-changes
        no bgp ebgp-requires-policy
        no bgp hard-administrative-reset
        no bgp graceful-restart notification
        no bgp network import-check
        neighbor eno1 arista01
        neighbor eno1 interface v6only remote-as 65033
      ip prefix-list loopbacks_ips seq 10 permit 0.0.0.0/0 le 32
      route-map correct_src permit 1
        match ip address prefix-list loopbacks_ips
        set src 10.0.0.99
      ip protocol bgp route-map correct_src
    '';
  };
}
