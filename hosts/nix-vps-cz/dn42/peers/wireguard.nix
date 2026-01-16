{
  services.custom-wireguard.interfaces = {
    "50-wg4242423914" = {
      listenPort = 23914;
      peerEndpoint = "de2.g-load.eu:20003";
      peerPublicKey = "B1xSG/XTJRLd+GrWDsB06BqnIq8Xud93YVh/LYYYtUY=";
      localAddressV6 = "fe80::ade1/64";
      peerAddressV6 = "fe80::ade0";
      vrf = "dn42";
    };
    "50-wg4242420207" = {
      listenPort = 20207;
      peerEndpoint = "router.fra1.routedbits.com:51033";
      peerPublicKey = "FIk95vqIJxf2ZH750lsV1EybfeC9+V8Bnhn8YWPy/l8=";
      localAddressV6 = "fe80::1033/128";
      peerAddressV6 = "fe80::0207/128";
      vrf = "dn42";
    };
  };
}
