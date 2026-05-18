{
  defaultTTL = 86400;
  zones = {
    "franta.dn42" = {
      "" = {
        ns = {
          data = [
            "ns0.franta.dn42"
          ];
        };
        a = {
          data = [ "172.23.234.30" ];
        };
        aaaa.data = "fdb7:c21f:f30f:53::";
      };
    };
    "f.0.3.f.f.1.2.c.7.b.d.f.ip6.arpa" = {
      "" = {
        ns = {
          data = [ "ns0.franta.dn42" ];
        };
      };
    };
  };
}
