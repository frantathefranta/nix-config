let
  _60Prefix = "2600:1702:6630:3fe";
  aSubnet = "${_60Prefix}a";
  dSubnet = "${_60Prefix}d";
  fSubnet = "${_60Prefix}f";
in
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
      "protactinium-mgmt".a.data = [ "10.32.10.70" ];
      "thorium-mgmt".a.data = [ "10.32.10.60" ];
      "actinium".cname.data = "actinium-mgmt.infra.franta.us";
      "thorium".cname.data = "thorium-mgmt.infra.franta.us";
      "protactinium".cname.data = "protactinium-mgmt.infra.franta.us";
      "actinium-nfs" = {
        a.data = [ "10.33.1.50" ];
        aaaa.data = [ "${fSubnet}:10:33:1:50" ];
      };
      "apc-rack-pdu01" = {
        a.data = [ "10.32.10.2" ];
        aaaa.data = [ "${dSubnet}:2c0:b7ff:fe86:c0a1" ];
      };
      "bmc-actinium".a.data = [ "10.32.10.5" ];
      "bmc-thorium".a.data = [ "10.32.10.6" ];
      "bmc-protactinium".a.data = [ "10.32.10.7" ];
      "arista-lo0" = {
        a.data = [ "10.0.0.2" ];
        aaaa.data = [ "${aSubnet}::2" ];
      };
      "arista".cname.data = "arista-lo0.infra.franta.us";
      "brocade-garage" = {
        a.data = [ "10.32.10.205" ];
        aaaa.data = [ "${dSubnet}:629c:9fff:fe37:cbac" ];
      };
      "brocade01-poe" = {
        a.data = [ "10.32.10.202" ];
        aaaa.data = [ "${dSubnet}:d6c1:9eff:fe43:1d00" ];
      };
      "platinum" = {
        a.data = [ "10.32.10.210" ];
        aaaa.data = [ "${dSubnet}:ba85:84ff:feb9:446e" ];
      };
      "eth-ex3400" = {
        a.data = [ "10.32.10.204" ];
        aaaa.data = [ "${dSubnet}:10:32:10:204" ];
      };
    };

    "cloud.franta.us" = {
      "" = {
        ns = {
          data = [
            "ns1.desec.io"
            "ns2.desec.org"
          ];
          ttl = 3600;
        };
      };
    };

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
