{ ... }:
{
  sessions = [];
  extraConfig = ''
      protocol bgp iBGP_cmh_v4 from dnpeers {
            #disabled;
            neighbor 172.23.234.17 as 4242421033;
            ipv4 {
                    next hop self;
                    import all;
                    export where dn42_export_filter(4,25,34);
                    import keep filtered;
            };

            ipv6 {
                    next hop self;
                    import none;
                    export none;
            };
      }

      protocol bgp iBGP_cmh_v6 from dnpeers {
            #disabled;
            neighbor fdb7:c21f:f30f::1 as 4242421033;
            ipv4 {
                    next hop self;
                    import none;
                    export none;
            };

            ipv6 {
                    next hop self;
                    import all;
                    export where dn42_export_filter(4,25,34);
                    import keep filtered;
            };
    }
  '';
}
