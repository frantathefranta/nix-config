{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    inputs.nnf.nixosModules.default
  ];
  networking = {
    firewall.enable = false;
    nat.enable = false;
    nftables.firewall = {
      enable = true;
      snippets = {
        nnf-common.enable = true;
        nnf-conntrack.enable = true;
        nnf-default-stopRuleset.enable = true;
        nnf-drop.enable = false; # see above, using our own drop rules
        nnf-loopback.enable = true;
        nnf-dhcpv6.enable = true;
        nnf-icmp.enable = true;
        nnf-ssh.enable = true;
        nnf-nixos-firewall.enable = false;
      };
      zones.untrusted = {
        interfaces = [ "wan0" ];
      };
      zones.mgmt = {
        interfaces = [
          "eth6"
          "mgmt"
        ];
      };
      zones.local_interfaces = {
        interfaces = [
          "lan0"
          "lan0.20"
          "lan0.50"
          "lan0.920"
        ];
      };
      zones.wifi = {
        interfaces = [
          "lan0.20"
        ];
      };
      zones.iot = {
        interfaces = [
          "lan0.50"
        ];
      };
      zones.lab_space = {
        ipv4Addresses = [
          "10.32.10.0/24"
          "10.33.0.0/16"
        ];
        ipv6Addresses = [ "2600:1702:6630:3fec::/63" ];
      };
      zones.plex = {
        ipv4Addresses = [ "10.32.10.210/24" ];
      };
      zones.hass = {
        ipv4Addresses = [
          "10.0.50.30/24"
        ];
      };
      zones.lan950 = {
        interfaces = [ "lan0.950" ];
      };
      rules = {
        wan_egress = {
          from = [
            "local_interfaces"
            "lan950"
          ];
          to = [ "untrusted" ];
          verdict = "accept";
          late = true;
          masquerade = true;
        };
        # Test rule for letting traffic from 920 to 950 (but not the other way)
        allow_hass_everywhere = {
          from = [ "hass" ];
          to = [ "local_interfaces" ];
          verdict = "accept";
        };
        allow_20_to_50 = {
          from = [ "wifi" ];
          to = [ "iot" ];
          verdict = "accept";
        };
        allow_wifi_to_iot = {
          from = [ "wifi" ];
          to = [ "iot" ];
          verdict = "accept";
        };
        allow_access_to_lab = {
          from = [ "local_interfaces" ];
          to = [ "lab_space" ];
          verdict = "accept";
        };
        allow_access_from_lab = {
          from = [ "lab_space" ];
          to = [ "local_interfaces" ];
          verdict = "accept";
        };
        allow_dns = {
          from = [
            "local_interfaces"
            "lan950"
          ];
          allowedUDPPorts = [ 53 ];
          to = [ "fw" ];
          verdict = "accept";
        };
        allow_dns_mgmt = {
          from = [ "mgmt" ];
          allowedTCPPorts = [ 8853 ];
          to = [ "fw" ];
          verdict = "accept";
        };
      };
    };
  };
}
