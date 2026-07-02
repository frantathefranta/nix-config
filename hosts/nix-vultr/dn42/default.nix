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
  };
}
