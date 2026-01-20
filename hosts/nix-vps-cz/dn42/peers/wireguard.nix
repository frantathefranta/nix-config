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
    "50-wg4242420263" = {
      listenPort = 20263;
      peerEndpoint = "de-fra1.flap42.eu:52026";
      peerPublicKey = "d7ICCZTiZaYlf9ueUuPlVV1QdLWLobIlCiI9fxet+H4=";
      peerAddressV6 = "fe80:4263::1:1a/128";
      localAddressV6 = "fe80:4263::2:1a/128";
      vrf = "dn42";
    };
    "50-wg4242422884" = {
      listenPort = 22884;
      peerEndpoint = "dn42-de-fra01.datenfass.com:21033";
      peerPublicKey = "kXxGLbuklKYCUhVS30DJKvn/hv2tgHwweGjd21VoqRQ=";
      peerAddressV6 = "fe80::2884/128";
      localAddressV6 = "fe80::1033:2884/128";
      vrf = "dn42";
    };
    "50-wg4242423088" = {
      listenPort = 23088;
      peerEndpoint = "v6.ams1-nl.dn42.6700.cc:21033";
      peerPublicKey = "AgXewx4akBG9QI9ClbJMcflmDY1rsdOslRTI/CL4PHk=";
      peerAddressV6 = "fe80::3088:194/128";
      localAddressV6 = "fe80::abcd/128";
      vrf = "dn42";
    };
  };
}
