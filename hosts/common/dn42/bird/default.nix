{
  config,
  lib,
  pkgs,
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
  ];
  bgp = import ../../../${config.networking.hostName}/dn42/peers/bgp.nix { };

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
    + lib.concatStrings (
      builtins.map (
        x:
        "protocol bgp ${x.name} from dnpeers {
           neighbor ${x.neigh} as ${x.as};
        ${
                  if x.multi || x.v4 then
                    "
        ipv4 { extended next hop on; import where dn42_import_filter(${x.link},25,34); export where dn42_export_filter(${x.link},25,34); import keep filtered; };
        "
                  else
                    ""
                }
        ${
                  if x.multi || x.v6 then
                    "
        ipv6 {
                extended next hop on;
                import where dn42_import_filter(${x.link},25,34);
                export where dn42_export_filter(${x.link},25,34);
                import keep filtered;
        };
        "
                  else
                    ""
                }
    }
        "
      ) bgp.sessions
    );
  };
}
