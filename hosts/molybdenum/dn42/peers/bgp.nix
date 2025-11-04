{ ... }:

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
  ];
  extraConfig = ''
    protocol bgp ROUTE_COLLECTOR
    {
      local as 4242421033;
      neighbor fd42:4242:2601:ac12::1 as 4242422602;

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
    protocol bgp arista
    {
      local as 4242421033;
      neighbor fe80::464c:a8ff:fede:3cf7%ens18 as 65033;

      # enable multihop as the collector is not locally connected
      #multihop;

      ipv4 {
        # export all available paths to the collector    
        add paths tx;

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
        # export all available paths to the collector    
        add paths tx;

        # import/export filters
        import none;
        export filter {
          # export all valid routes
          if ( is_self_net_v6() && source ~ [ RTS_STATIC, RTS_BGP ] )
          then {
            accept;
          }
          reject;
        };
      };
    }
  '';
}
