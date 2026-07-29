{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./wireguard.nix
  ];

  meta.dn42 = {
    host = {
      ipv4 = "172.23.234.20";
      ipv6Suffix = ":1";
      ipv4PrefixLength = 32;
      ipv6Subnet = "0200"; 
    };
    region = 41; # Europe
    country = 616;
    bandwidth = 25;
    extraBirdConfig = ''
      protocol bgp ibgp_yukisino from ibgp_peers {
        neighbor fe80::ff00:1033%ix_yukisino internal;
        rr client on;
        bfd on;
        direct;
        ipv4 { extended next hop on; next hop self; import where source = RTS_BGP && is_valid_network() && !is_self_net(); export where source = RTS_BGP && is_valid_network() && !is_self_net(); };
        ipv6 { extended next hop on; next hop self; import where source = RTS_BGP && is_valid_network_v6() && !is_self_net_v6(); export where source = RTS_BGP && is_valid_network_v6() && !is_self_net_v6(); };
      } 
    '';
  };
}
