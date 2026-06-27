{
  config,
  lib,
  pkgs,
  ...
}:

let
  subnet = builtins.toString config.meta.dn42.host.ipv6Subnet;
in
{
  services.custom-wireguard.interfaces = {
    "ibgp_us1" = {
      listenPort = 24001;
      peerEndpoint = "us1.dn42.franta.us:21033";
      peerPublicKey = "us1UyUrDb+609N10WRholfb4Q6XuOGvx23uPMQbJdTg=";
      localAddressV6 = "fe80::${subnet}:1033/128";
      peerAddressV6 = "fe80::3:1033/128";
      latency = 5;
    };
    # "ebgp_4242423914" = {
    #   listenPort = 23914;
    #   peerEndpoint = "de2.g-load.eu:20003";
    #   peerPublicKey = "B1xSG/XTJRLd+GrWDsB06BqnIq8Xud93YVh/LYYYtUY=";
    #   localAddressV6 = "fe80::ade1/64";
    #   peerAddressV6 = "fe80::ade0";
    # };
  };
}
