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
      ipv4PrefixLength = 32;
      ipv6Subnet = "0300"; # TODO: Change when nix-vps-cz is deleted
    };
    region = 41; # Europe
    country = 616;
  };
}
