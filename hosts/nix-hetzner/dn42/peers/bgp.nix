{ ... }:
{
  sessions = [
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
      neigh = "fe80::42:2601:36:1%wg4242422601";
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
  ];
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
