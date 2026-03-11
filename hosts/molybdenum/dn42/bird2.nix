{
  config,
  lib,
  pkgs,
  ...
}:

let
  bgp = import peers/bgp.nix { };
  hostIPv4 = builtins.elemAt config.networking.interfaces.ens18.ipv4.addresses 0;
  address = hostIPv4.address;
in
{
  services = {
    bird-lg = {
      # package = unstable.bird-lg;
      proxy = {
        enable = true;
        listenAddresses = "0.0.0.0:8000";
        allowedIPs = [
          "172.23.234.17"
          "fdb7:c21f:f30f::1"
          "fdb7:c21f:f30f:1::1"
          "fdb7:c21f:f30f:2::1"
        ];
        birdSocket = "/var/run/bird/bird.ctl";
      };
      frontend = {
        enable = true;
        whois = "whois.dn42";
        netSpecificMode = "dn42";
        servers = [
          "us-cmh"
          "us-pdx"
          "cz-prg"
        ];
        domain = "franta.dn42";
        listenAddresses = [
          "${address}:5000"
          "[fdb7:c21f:f30f::1]:5000"
        ];
      };
    };
    bird = {
      enable = true;
      checkConfig = true;
      config =
        builtins.readFile ./bird.conf
        + lib.concatStrings (
          builtins.map (
            x:
            "
      protocol bgp ${x.name} from dnpeers {
        neighbor ${x.neigh} as ${x.as};
        ${
                      if x.multi || x.v4 then
                        "
        ipv4 {
                extended next hop on;
                import where dn42_import_filter(${x.link},25,34);
                export where dn42_export_filter(${x.link},25,34);
                import keep filtered;
        };
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
        )
        + builtins.readFile ./peers/bird-extra.conf;
    };
    prometheus.exporters.bird = {
      enable = true;
      openFirewall = false;
      listenAddress = address;
    };
  };
}
