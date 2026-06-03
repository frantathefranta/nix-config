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
    "infra.franta.us" = {
      "" = {
        ns = {
          data = [ "ns1.franta.us" ];
          ttl = 3600;
        };
      };
      "actinium-mgmt".a.data = [ "10.32.10.50" ];
      "actinium-nfs" = {
        a.data = [ "10.33.1.50" ];
        aaaa.data = [ "2600:1702:6630:3fef:10:33:1:50" ];
      };
      "apc-rack-pdu01" = {
        a.data = [ "10.32.10.2" ];
        aaaa.data = [ "2600:1702:6630:3fed:2c0:b7ff:fe86:c0a1" ];
      };
      "bmc-actinium".a.data = [ "10.32.10.5" ];
      "bmc-thorium".a.data = [ "10.32.10.6" ];
      "bmc-protactinium".a.data = [ "10.32.10.7" ];
      "brocade-garage" = {
        a.data = [ "10.32.10.205" ];
        aaaa.data = [ "2600:1702:6630:3fed:629c:9fff:fe37:cbac" ];
      };
      "brocade01-poe" = {
        a.data = [ "10.32.10.202" ];
        aaaa.data = [ "2600:1702:6630:3fed:d6c1:9eff:fe43:1d00" ];
      };
      "platinum" = {
        a.data = [ "10.32.10.210" ];
        aaaa.data = [ "2600:1702:6630:3fed:ba85:84ff:feb9:446e" ];
      };
      "protactinium-mgmt".a.data = [ "10.32.10.70" ];
      "thorium-mgmt".a.data = [ "10.32.10.60" ];
      "eth-ex3400" = {
        a.data = [ "10.32.10.204" ];
        aaaa.data = [ "2600:1702:6630:3fed:10:32:10:204" ];
      };
    };
    # "10.in-addr.arpa" = {
    #   "" = {
    #     ns = {
    #       data = [ "ns1.franta.us" ];
    #       ttl = 3600;
    #     };
    #   };
    # };
    "e.f.3.0.3.6.6.2.0.7.1.0.0.6.2.ip6.arpa" = {
      "" = {
        ns = {
          data = [ "ns1.franta.us" ];
          ttl = 3600;
        };
      };
    };
  };
}
