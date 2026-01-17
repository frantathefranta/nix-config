{ ... }:
{
  sessions = [
    {
      multi = true;
      name = "dn42_Kioubit";
      neigh = "fe80::ade0%wg4242423914";
      as = "4242423914";
      link = "3";
    }
    {
      multi = true;
      name = "dn42_RoutedBits";
      neigh = "fe80::0207%wg4242420207";
      as = "4242420207";
      link = "3";
    }
  ];
  extraConfig = ''
      protocol bgp iBGP_cmh_v6 from dnpeers {
            vrf "dn42";
            neighbor fdb7:c21f:f30f::1 as 4242421033;
            source address OWNIPv6;
            bfd on;
            ipv4 {
                    table DN42v4;
                    extended next hop on;
                    next hop self;
                    import all;
                    export where dn42_export_filter(5,25,34);
                    import keep filtered;
            };
            ipv6 {
                    table DN42v6;
                    extended next hop on;
                    next hop self;
                    import all;
                    export where dn42_export_filter(5,25,34);
                    import keep filtered;
            };
      }
      protocol bgp iBGP_pdx_v6 from dnpeers {
            vrf "dn42";
            neighbor fdb7:c21f:f30f:1::1 as 4242421033;
            ipv4 {
                    table DN42v4;
                    extended next hop on;
                    next hop self;
                    import all;
                    export where dn42_export_filter(6,25,34);
                    import keep filtered;
            };

            ipv6 {
                    table DN42v6;
                    extended next hop on;
                    next hop self;
                    import all;
                    export where dn42_export_filter(6,25,34);
                    import keep filtered;
            };
    }
    protocol bgp ROUTE_COLLECTOR {
        vrf "dn42";
      local as 4242421033;
      neighbor fd42:d42:d42:179::1 as 4242422602;

      # enable multihop as the collector is not locally connected
      multihop;

      ipv4 {
        table DN42v4;
        # export all available paths to the collector    
        add paths tx;

        # import/export filters
        import none;
        export filter {
          # export all valid routes
          if ( is_valid_network() && source ~ [ RTS_STATIC, RTS_BGP ] )
          then {
            accept;
          }
          reject;
        };
      };

      ipv6 {
        table DN42v6;
        # export all available paths to the collector    
        add paths tx;

        # import/export filters
        import none;
        export filter {
          # export all valid routes
          if ( is_valid_network_v6() && source ~ [ RTS_STATIC, RTS_BGP ] )
          then {
            accept;
          }
          reject;
        };
      };
    }
  '';
}
