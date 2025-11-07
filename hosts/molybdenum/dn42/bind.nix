{
  services.bind = {
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
      zone "dn42" {
        type forward;
        forwarders { 172.20.0.53; fd42:d42:d42:54::1; };
      };
      zone "20.172.in-addr.arpa" {
        type forward;
        forwarders { 172.20.0.53; fd42:d42:d42:54::1; };
      };
      zone "21.172.in-addr.arpa" {
        type forward;
        forwarders { 172.20.0.53; fd42:d42:d42:54::1; };
      };
      zone "22.172.in-addr.arpa" {
        type forward;
        forwarders { 172.20.0.53; fd42:d42:d42:54::1; };
      };
      zone "23.172.in-addr.arpa" {
        type forward;
        forwarders { 172.20.0.53; fd42:d42:d42:54::1; };
      };
      zone "10.in-addr.arpa" {
        type forward;
        forwarders { 172.20.0.53; fd42:d42:d42:54::1; };
      };
      zone "d.f.ip6.arpa" {
        type forward;
        forwarders { 172.20.0.53; fd42:d42:d42:54::1; };
      };
    '';
    forward = "only";
    # listenOn = [
    #   "!10.32.10.0/24"
    #   "0.0.0.0/0"
    # ];
    zones = {
      "franta.dn42" = {
        file = "/etc/zones/franta.dn42";
        master = true;
      };
      "16/28.234.23.172.in-addr.arpa" = {
        file = "/etc/zones/ipv4.reverse";
        master = true;
      };
      "f.0.3.f.f.1.2.c.7.b.d.f.ip6.arpa" = {
        file = "/etc/zones/ipv6.reverse";
        master = true;
      };
    };
  };
}
