{
  config,
  lib,
  pkgs,
  ...
}:

let
  bgp = import peers/bgp.nix { };
  # hostIPv4 = builtins.elemAt config.networking.interfaces.ens18.ipv4.addresses 0;
  # address = hostIPv4.address;
in
{
  services = {
    bird-lg = {
      package = pkgs.unstable.bird-lg;
      proxy = {
        enable = true;
        listenAddresses = "[fdb7:c21f:f30f:2::1]:8000";
        extraArgs = [
          "--vrf=dn42"
        ];
        allowedIPs = [
          "172.23.234.17"
          "fdb7:c21f:f30f::1"
          "fdb7:c21f:f30f:1::1"
          "fdb7:c21f:f30f:2::1"
        ];
        birdSocket = "/var/run/bird/bird.ctl";
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
    # prometheus.exporters.bird = {
    #   enable = true;
    #   openFirewall = false;
    #   listenAddress = address;
  };
  systemd.services.bird.after = [ config.systemd.services.systemd-networkd.name ];
}
