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
  };
}
