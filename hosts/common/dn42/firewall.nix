{
  inputs,
  config,
  lib,
  ...
}:

let
  wanInterface = config.systemd.network.networks."10-wan".matchConfig.Name;
  networkInterfaces =
    prefix:
    lib.mapAttrsToList (_name: net: net.matchConfig.Name) (
      lib.filterAttrs (name: _: lib.hasPrefix prefix name) config.systemd.network.networks
    );
  wgInterfaces = networkInterfaces "ibgp";
  ospfInterfaces = networkInterfaces "ebgp";
in
{
  imports = [
    inputs.nnf.nixosModules.default
  ];

  networking = {
    nat.enable = false;
    firewall = {
      enable = lib.mkForce false;
    };
    nftables.chains.forward.filter = {
      after = [ "hook" ];
      rules = [
        "iifname { ibgp*, ebgp* } accept"
        "oifname { ibgp*, ebgp* } accept"
      ];
    };
    nftables.firewall = {
      enable = true;
      snippets = {
        nnf-common.enable = true;
        # nnf-conntrack.enable = false;
        # nnf-drop.enable = false;
      };
      zones.untrusted.interfaces = [ wanInterface ];
      zones.dummy_ospf.interfaces = [ "dummy_ospf" ];
      zones.wg_dn42 = lib.mkIf (wgInterfaces != [ ]) { interfaces = wgInterfaces; };
      zones.ospf_wg = lib.mkIf (ospfInterfaces != [ ]) { interfaces = ospfInterfaces; };
      zones.my_dn42_prefix.ipv6Addresses = [
        "${config.meta.dn42.ipv6Prefix48}::/48"
      ];
      zones.dn42_subnets = {
        ipv4Addresses = [ "172.20.0.0/14" ];
        ipv6Addresses = [ "fd00::/8" ];
      };
      zones.ospf = {
        ingressExpression = [
          "ip protocol ospfigp counter"
          "ip6 nexthdr ospfigp counter"
        ];
        egressExpression = [
          "ip protocol ospfigp counter"
          "ip6 nexthdr ospfigp counter"
        ];
      };
      rules = {
        allow_wg_ingress = {
          from = [ "untrusted" ];
          to = [ "fw" ];
          allowedUDPPortRanges = [
            {
              from = 20000;
              to = 30000;
            }
          ];
        };
        allow_bgp_from_peers = {
          from = [
            "dummy_ospf"
          ]
          ++ lib.optionals (ospfInterfaces != [ ]) [ "ospf_wg" ]
          ++ lib.optionals (wgInterfaces != [ ]) [ "wg_dn42" ];
          to = [ "fw" ];
          allowedTCPPorts = [ 179 ];
        };
        allow_ospf_traffic = {
          from = [ "ospf" ];
          to = [ "fw" ];
          verdict = "accept";
        };
        allow_ospf_bfd = lib.mkIf (ospfInterfaces != [ ]) {
          from = [ "ospf_wg" ];
          to = [ "fw" ];
          allowedUDPPorts = [ 3784 ];
        };
        allow_ibgp_bfd = {
          from = [ "my_dn42_prefix" ];
          to = [ "fw" ];
          allowedUDPPorts = [ 4784 ];
        };
        allow_dn42_traceroute = {
          from = [ "dn42_subnets" ];
          to = [ "fw" ];
          allowedUDPPortRanges = [
            {
              from = 33434;
              to = 33689;
            }
          ];
        };
        allow_bird_lg_proxy = {
          from = [ "my_dn42_prefix" ];
          to = [ "fw" ];
          allowedTCPPorts = [ 8000 ];
        };
      };
    };
  };
}
