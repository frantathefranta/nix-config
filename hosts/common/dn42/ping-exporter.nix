{ config, lib, outputs, ... }:
let
  dn42Hosts = lib.filterAttrs (
    name: cfg:
      name != config.networking.hostName
      && lib.attrByPath [ "config" "meta" "dn42" "host" "ipv4" ] null cfg != null
  ) outputs.nixosConfigurations;

  pingTargets = lib.concatLists (
    lib.mapAttrsToList (
      _name: cfg:
        let
          host = cfg.config.meta.dn42.host;
        in
        lib.optional (host.ipv4 != null) host.ipv4
        ++ lib.optional (host.resolvedIPv6 != null) host.resolvedIPv6
    ) dn42Hosts
  );
in
{
  services.prometheus.exporters.ping = {
    enable = true;
    openFirewall = false;
    settings.targets = pingTargets;
  };
  networking.nftables.firewall.rules.allow_ping_exporter = {
    from = [
      "my_dn42_prefix"
      "my_home_prefix"
    ];
    to = [ "fw" ];
    allowedTCPPorts = [ config.services.prometheus.exporters.ping.port ];
  };
}
