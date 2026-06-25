{
  config,
  lib,
  pkgs,
  ...
}:

{
  meta.dn42.host = {
    ipv4 = "172.23.234.19";
    ipv4PrefixLength = 32;
    ipv6Subnet = "0200";
  };
}
