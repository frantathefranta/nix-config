{ ... }:

# (64511, 1) :: latency \in (0, 2.7ms]
# (64511, 2) :: latency \in (2.7ms, 7.3ms]
# (64511, 3) :: latency \in (7.3ms, 20ms]
# (64511, 4) :: latency \in (20ms, 55ms]
# (64511, 5) :: latency \in (55ms, 148ms]
# (64511, 6) :: latency \in (148ms, 403ms]
# (64511, 7) :: latency \in (403ms, 1097ms]
# (64511, 8) :: latency \in (1097ms, 2981ms]
# (64511, 9) :: latency > 2981ms
# (64511, x) :: latency \in [exp(x-1), exp(x)] ms (for x < 10)
 
{
  sessions = [
    {
      multi = true;
      name = "Kioubit";
      neigh = "fe80::ade0%wg4242423914";
      as = "4242423914";
      link = "4";
    }
    {
      multi = true;
      name = "RoutedBits";
      neigh = "fe80::0207%wg4242420207";
      as = "4242420207";
      link = "3";
    }
    {
      multi = true;
      name = "TECH9";
      neigh = "fe80::1588%wg4242421588";
      as = "4242421588";
      link = "3";
    }
    {
      multi = true;
      name = "iedon";
      neigh = "fe80::2189:124%wg4242422189";
      as = "4242422189";
      link = "4";
    }
    {
      multi = true;
      name = "moe233";
      neigh = "fe80::0253%wg4242420253";
      as = "4242420253";
      link = "5";
    }
    {
      multi = true;
      name = "larecc";
      neigh = "fe80::3035:137%wg4242423035";
      as = "4242423035";
      link = "3";
    }
    {
      multi = true;
      name = "burble";
      neigh = "fe80::42:2601:29:1%wg4242422601";
      as = "4242422601";
      link = "4";
    }
    {
      multi = true;
      name = "dn42_nedifinita";
      neigh = "fe80::454:2%wg4242420454";
      as = "4242420454";
      link = "4";
    }
    {
      multi = true;
      name = "dn42_flipflap";
      neigh = "fe80:3263::1:16%wg4242420263";
      as = "4242420263";
      link = "3";
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
      protocol bgp iBGP_pdx from dnpeers {
            neighbor fdb7:c21f:f30f:1::1 as 4242421033;
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
                    next hop self;
                    import all;
                    export where ibgp_export_filter(4,25,34);
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
                    export where dn42_export_filter(5,25,34);
                    import keep filtered;
            };

            ipv6 {
                    extended next hop on;
                    next hop self;
                    import all;
                    export where ibgp_export_filter(5,25,34);
                    import keep filtered;
            };
    }
    protocol bgp qotom
    {
      local as 4242421033;
      neighbor fe80::6:5032:1033%wg_qotom as 65032;
      ipv4 {
        extended next hop on;
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
        extended next hop on;
        import filter {
          if ( is_loopback_v6() && source ~ [ RTS_STATIC, RTS_BGP ] )
          then {
            accept;
          }
        reject; 
        };
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
    protocol bgp arista
    {
      local as 4242421033;
      neighbor fe80::464c:a8ff:fede:3cf7%ens18 as 65033;

      ipv4 {
        # import/export filters
        import none;
        export filter {
          # export all valid routes
          if ( is_self_net() && source ~ [ RTS_STATIC, RTS_BGP ] )
          then {
            accept;
          }
          reject;
        };
      };

      ipv6 {
        # import/export filters
        import filter {
          if ( is_loopback_v6() && source ~ [ RTS_STATIC, RTS_BGP ] )
          then {
            accept;
          }
        reject; 
        };
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
