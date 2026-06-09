{ config, ... }:
{
  services.bind = {
    checkConfig = false;
    cacheNetworks = [
      "127.0.0.1/32"
      "172.20.0.0/14"
      "fd00::/8"
      "::1/128"
    ];
    enable = true;
    extraOptions = ''
      empty-zones-enable no;
      recursion yes;
      dnssec-validation auto;
      auth-nxdomain no;    # conform to RFC1035
      validate-except {
        "dn42";
        "20.172.in-addr.arpa";
        "21.172.in-addr.arpa";
        "22.172.in-addr.arpa";
        "23.172.in-addr.arpa";
        "10.in-addr.arpa";
        "d.f.ip6.arpa";
      };
    '';
    forwarders = [
      "1.1.1.1"
      "1.0.0.1"
      "2606:4700:4700::1111"
      "2606:4700:4700::1001"
    ];
    extraConfig = ''
      include "${config.sops.secrets."bind/tsigkey".path}";
      zone "dn42" {
        type forward;
        forwarders { 172.20.0.53; 172.23.0.53; fd42:d42:d42:54::1; fd42:d42:d42:53::1; };
      };
      zone "20.172.in-addr.arpa" {
        type forward;
        forwarders { 172.20.0.53; 172.23.0.53; fd42:d42:d42:54::1; fd42:d42:d42:53::1; };
      };
      zone "21.172.in-addr.arpa" {
        type forward;
        forwarders { 172.20.0.53; 172.23.0.53; fd42:d42:d42:54::1; fd42:d42:d42:53::1; };
      };
      zone "22.172.in-addr.arpa" {
        type forward;
        forwarders { 172.20.0.53; 172.23.0.53; fd42:d42:d42:54::1; fd42:d42:d42:53::1; };
      };
      zone "23.172.in-addr.arpa" {
        type forward;
        forwarders { 172.20.0.53; 172.23.0.53; fd42:d42:d42:54::1; fd42:d42:d42:53::1; };
      };
      zone "10.in-addr.arpa" {
        type forward;
        forwarders { 172.20.0.53; 172.23.0.53; fd42:d42:d42:54::1; fd42:d42:d42:53::1; };
      };
      zone "d.f.ip6.arpa" {
        type forward;
        forwarders { 172.20.0.53; 172.23.0.53; fd42:d42:d42:54::1; fd42:d42:d42:53::1; };
      };
    '';
    forward = "only";
    zones = {
      "franta.dn42" = {
        file = "/etc/zones/franta.dn42";
        master = true;
        slaves = [ "key franta.dn42." ]; # This should just be for IPs but works for keys as well (as of 25.11)
        extraConfig = ''
          allow-update { key franta.dn42.; };
        '';
      };
      "16/28.234.23.172.in-addr.arpa" = {
        file = "/etc/zones/ipv4.reverse";
        master = true;
        extraConfig = ''
          update-policy local;
        '';
      };
      "f.0.3.f.f.1.2.c.7.b.d.f.ip6.arpa" = {
        file = "/etc/zones/ipv6.reverse";
        master = true;
        slaves = [ "key franta.dn42." ]; # This should just be for IPs but works for keys as well (as of 25.11)
        extraConfig = ''
          allow-update { key franta.dn42.; };
        '';
      };
    };
  };
  sops.secrets."bind/tsigkey" = {
    sopsFile = ../secrets.yaml;
    owner = config.users.users.named.name;
    group = config.users.users.named.group;
  };
}
