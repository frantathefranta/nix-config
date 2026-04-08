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
      zones.local_interfaces = {
        interfaces = [
          "lan0"
          "lan0.20"
          "lan0.50"
        ];
      };
      rules = {
        wan_egress = {
          from = [ "local_interfaces" ];
          to = [ "untrusted" ];
          verdict = "accept";
          late = true;
          masquerade = true;
        };
      };
    };
  };
}
