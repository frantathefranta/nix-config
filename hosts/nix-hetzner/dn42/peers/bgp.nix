{ ... }:
{
  sessions = [
    {
      multi = true;
      name = "dn42_moe233";
      neigh = "fe80::0253%wg4242420253";
      as = "4242420253";
      link = "4";
    }
    {
      multi = true;
      name = "dn42_Kioubit";
      neigh = "fe80::ade0%wg4242423914";
      as = "4242423914";
      link = "4";
    }
    {
      multi = true;
      name = "dn42_RoutedBits";
      neigh = "fe80::0207%wg4242420207";
      as = "4242420207";
      link = "2";
    }
    {
      multi = true;
      name = "dn42_larecc";
      neigh = "fe80::3035:132%wg4242423035";
      as = "4242423035";
      link = "4";
    }
    {
      multi = true;
      name = "dn42_burble";
      neigh = "fe80::42:2601:2a:1%wg4242422601";
      as = "4242422601";
      link = "3";
    }
    {
      multi = true;
      name = "dn42_nedifinita";
      neigh = "fe80::454%wg4242420454";
      as = "4242420454";
      link = "3";
    }
    {
      multi = true;
      name = "dn42_tech9";
      neigh = "fe80::1588%wg4242421588";
      as = "4242421588";
      link = "4";
    }
    {
      multi = true;
      name = "dn42_sunnet";
      neigh = "fe80::3088:191%wg4242423088";
      as = "4242423088";
      link = "3";
    }
    {
      multi = true;
      name = "dn42_markround";
      neigh = "fe80::401%wg4242420401";
      as = "4242420401";
      link = "1";
    }
  ];
  extraConfig = ''
    protocol bgp ROUTE_COLLECTOR
    {
      local as 4242421033;
      neighbor fd42:d42:d42:179::1 as 4242422602;

      # enable multihop as the collector is not locally connected
      multihop;

      ipv4 {
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
      protocol bgp iBGP_cmh from dnpeers {
            neighbor fdb7:c21f:f30f::1 as 4242421033;
            bfd on;
            source address OWNIPv6;
            ipv4 {
                    extended next hop on;
                    next hop self;
                    import all;
                    export where dn42_export_filter(4,25,34);
                    import keep filtered;
            };
            ipv6 {
                    extended next hop on;
                    next hop self;
                    import all;
                    export where dn42_export_filter(4,25,34);
                    import keep filtered;
            };
    }
      protocol bgp iBGP_prg from dnpeers {
            neighbor fdb7:c21f:f30f:2::1 as 4242421033;
            bfd on;
            source address OWNIPv6;
            ipv4 {
                    extended next hop on;
                    next hop self;
                    import all;
                    export where dn42_export_filter(6,25,34);
                    import keep filtered;
            };

            ipv6 {
                    extended next hop on;
                    next hop self;
                    import all;
                    export where dn42_export_filter(6,25,34);
                    import keep filtered;
            };
    }
  '';
}
