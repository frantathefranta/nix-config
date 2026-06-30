{
  config,
  lib,
  pkgs,
  dn42Of,
  ...
}:

let
  routerID = config.meta.dn42.host.ipv4;
  OWNIPv6 = "${config.meta.dn42.host.resolvedIPv6Prefix64}::1";
  loopback = config.systemd.network.netdevs."10-dummy_ospf".netdevConfig.Name;
  region = config.meta.dn42.region;
  country = config.meta.dn42.country + 1000;
  confFiles = map builtins.readFile [
    ./filters.conf
    ./protocols.conf
    ./roa.conf
    ./templates.conf
    ./communities.conf
    ./peers.conf
  ];
  # TODO: Remove if unnecessary
  # bgp = import ../../../${config.networking.hostName}/dn42/peers/bgp.nix { };

  stripPrefixLen = addr: builtins.head (lib.splitString "/" addr);

  wgSessions = lib.filterAttrs
    (name: _: lib.hasPrefix "ibgp" name || lib.hasPrefix "ebgp" name)
    config.services.custom-wireguard.interfaces;

  mkWgBgpSession = name: iface:
    let
      isIbgp = lib.hasPrefix "ibgp" name;
      template = if isIbgp then "ibgp_peers" else "dnpeers";
      neighborLine =
        if isIbgp
        then "neighbor ${(dn42Of iface.peerHostname).resolvedIPv6} as 4242421033;"
        else "neighbor ${stripPrefixLen iface.peerAddressV6}%${name} as ${lib.last (lib.splitString "_" name)};";
      latency = if iface.latency != null then iface.latency else 1;
    in
    if isIbgp then ''
      protocol bgp ${name} from ${template} {
        ${neighborLine}
        bfd on;
        source address OWNIPv6;
        ipv4 { extended next hop on; next hop self; import all; export where dn42_export_filter(${toString latency},25,34); import keep filtered; };
        ipv6 { extended next hop on; next hop self; import all; export where ibgp_export_filter(${toString latency},25,34); import keep filtered; };
      }
    ''
    else ''
      protocol bgp ${name} from ${template} {
        ${neighborLine}
        ipv4 { extended next hop on; import where dn42_import_filter(${toString latency},25,34); export where dn42_export_filter(${toString latency},25,34); import keep filtered; };
        ipv6 { extended next hop on; import where dn42_import_filter(${toString latency},25,34); export where dn42_export_filter(${toString latency},25,34); import keep filtered; };
      }
    '';
in
{
  services.bird = {
    enable = true;
    config = ''
      define OWNAS = 4242421033;
      define OWNIP = ${routerID};
      define OWNIPv6 = ${OWNIPv6};
      define OWNNET = 172.23.234.16/28;
      define OWNNETv6 = fdb7:c21f:f30f::/48;
      define OWNNETSET = [172.23.234.16/28+];
      define OWNNETSETv6 = [fdb7:c21f:f30f::/48+];
      define DN_REGION_GEO = ${builtins.toString region};
      define DN_REGION_COUNTRY = ${builtins.toString country};
      define LOOPBACK = "${loopback}";

      router id OWNIP;
    ''
    + builtins.concatStringsSep "\n" confFiles
    + lib.concatStrings (lib.mapAttrsToList mkWgBgpSession wgSessions)
    + config.meta.dn42.extraBirdConfig;
  };
}
