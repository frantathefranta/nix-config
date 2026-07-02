{ config, ... }:

let
  dummyDN42IPv4 = "${config.meta.dn42.host.ipv4}/${builtins.toString config.meta.dn42.host.ipv4PrefixLength}";
  dummyDN42IPv6 = "${config.meta.dn42.host.resolvedIPv6Prefix64}::1/128";
in
{
  systemd.network.netdevs."10-dummy_ospf" = {
    netdevConfig = {
      Name = "dummy_ospf";
      Kind = "dummy";
    };
  };
  systemd.network.networks."10-dummy_ospf" = {
    matchConfig.Name = "dummy_ospf";
    address = [
      dummyDN42IPv4
      dummyDN42IPv6
    ];
    networkConfig = {
      LinkLocalAddressing = false;
    };
  };
  services.prometheus.exporters.wireguard = {
    enable = true;
    listenAddress = "::";
  };
  networking.nftables.firewall.rules.allow_wg_exporter = {
    from = [
      "my_dn42_prefix"
      "my_home_prefix"
    ];
    to = [ "fw" ];
    allowedTCPPorts = [ config.services.prometheus.exporters.wireguard.port ];
  };

}
