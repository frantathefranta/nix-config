# Allocations for routed containers on nix-bastion.
{
  uplink = "ens18";
  localAS = 65011;
  peerAS = 65033;
  routerId = "10.0.10.11";
  localLinkLocal = "fe80::10:32:10:11";
  peerLinkLocal = "fe80::464c:a8ff:fede:3cf7";

  ipv4Prefix = "10.233.1.0/24";
  ipv6Prefix = "2600:1702:6630:3fec:1032:1011::/96";

  omp = {
    # Reserve 10.233.1.0/30 and 2600:1702:6630:3fec:1032:1011:1:0/112.
    # Address options use peer host routes, not these allocation masks.
    hostIPv4 = "10.233.1.1";
    localIPv4 = "10.233.1.2";
    hostIPv6 = "2600:1702:6630:3fec:1032:1011:1:1";
    localIPv6 = "2600:1702:6630:3fec:1032:1011:1:2";
  };
}
