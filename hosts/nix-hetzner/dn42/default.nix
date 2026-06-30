{ config, ... }:
{
  imports = [
    ./peers/wireguard.nix
  ];

  meta.dn42.host = {
    ipv4 = "172.23.234.18";
    ipv6Subnet = "0100";
    ipv6 = "fdb7:c21f:f30f:100::1";
  };
  meta.dn42.region = 44;
  meta.dn42.country = 840;

  networking.domains = {
    defaultTTL = 86400;
    subDomains."us-pdx.franta.dn42" = {
      a.data = config.meta.dn42.host.ipv4;
      aaaa.data = config.meta.dn42.host.resolvedIPv6;
    };
  };

  services.bird-lg.proxy = {
    enable = true;
    listenAddresses = "[${config.meta.dn42.host.resolvedIPv6}]:8000";
    allowedIPs = [ "${config.meta.dn42.ipv6Prefix48}::/48" ];
    birdSocket = "/var/run/bird/bird.ctl";
  };
}
