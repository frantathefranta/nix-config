{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

let
  dn42_dummy_ipv6 = "fdb7:c21f:f30f:100::1";
  networkInterfaces =
    prefix:
    lib.mapAttrsToList (_name: net: net.matchConfig.Name) (
      lib.filterAttrs (name: _: lib.hasPrefix prefix name) config.systemd.network.networks
    );
in

{
  imports = [
    inputs.nixos-dns.nixosModules.dns
    inputs.nnf.nixosModules.default
    ./bird.nix
    ./peers/wireguard.nix
  ];
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.rp_filter" = 0;
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv4.conf.default.rp_filter" = 0;
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };
  networking = {
    domains = {
      enable = true;
      defaultTTL = 86400;
      baseDomains."franta.dn42" = { };
      subDomains."us-pdx.franta.dn42" = {
        a.data = "172.23.234.18";
        aaaa.data = dn42_dummy_ipv6;
      };
    };
    nat.enable = false;
    firewall = {
      enable = lib.mkForce false;
    };
    nftables.firewall = {
      enable = true;
      snippets.nnf-common.enable = true;
      zones.untrusted.interfaces = [ "eth0" ];
      zones.wg_dn42.interfaces = networkInterfaces "50-wg";
      zones.ospf_wg.interfaces = networkInterfaces "50-ospf";
      zones.dn42_ibgp_peers.ipv6Addresses = [
        "fdb7:c21f:f30f::1"
        "fdb7:c21f:f30f:200::1"
      ];
      zones.dn42_subnets = {
        ipv4Addresses = [ "172.20.0.0/14" ];
        ipv6Addresses = [ "fd00::/8" ];
      };
      zones.ospf = {
        ingressExpression = [
          "ip protocol ospfigp"
          "ip6 nexthdr ospfigp"
        ];
        egressExpression = [
          "ip protocol ospfigp"
          "ip6 nexthdr ospfigp"
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
            "ospf_wg"
            "wg_dn42"
          ];
          to = [ "fw" ];
          allowedTCPPorts = [ 179 ];
        };
        allow_ospf_traffic = {
          from = [ "ospf" ];
          to = [ "fw" ];
          verdict = "accept";
        };
        allow_ospf_bfd = {
          from = [ "ospf_wg" ];
          to = [ "fw" ];
          allowedUDPPorts = [ 3784 ];
        };
        allow_ibgp_bfd = {
          from = [ "dn42_ibgp_peers" ];
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
          from = [ "dn42_ibgp_peers" ];
          to = [ "fw" ];
          allowedTCPPorts = [ 8000 ];
        };
      };
    };
  };
  environment.systemPackages = [ pkgs.wireguard-tools ];
  systemd.network.netdevs."10-dummy_ospf" = {
    netdevConfig = {
      Name = "dummy_ospf";
      Kind = "dummy";
    };
  };
  systemd.network.networks."10-dummy_ospf" = {
    matchConfig.Name = "dummy_ospf";
    address = [
      "172.23.234.18"
      "${dn42_dummy_ipv6}/128"
    ];
    dns = [ "fdb7:c21f:f30f:53::" ];
    domains = [
      "~dn42"
      "~d.f.ip6.arpa"
    ];
    networkConfig = {
      LinkLocalAddressing = false;
    };
  };
  # systemd.network.networks."50-ospf_molybdenum" = {
  #   dns = [ "fdb7:c21f:f30f:53::" ];
  #   domains = [
  #     "~.dn42"
  #     "~.d.f.ip6.arpa"
  #   ];
  # };
}
