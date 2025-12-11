{
  services.custom-wireguard.interfaces = {
    "50-wg4242420454" = {
      listenPort = 20454;
      peerEndpoint = "dn42a.nedifinita.com:54876";
      peerPublicKey = "8EXT6zciVdil3Zg6dqB0YT2SssTh2OTKDeBBfrVGUkE=";
      peerAddressV6 = "fe80::454";
      localAddressV6 = "fe80::1033:0454/64";
    };
    "50-wg4242422601" = {
      listenPort = 22601;
      peerEndpoint = "dn42-us-fre1.burble.com:21033";
      peerPublicKey = "aBSm40KZbXnzbZNDGgPgqxONrmDmO0iMbkJ10ZJ9rR4=";
      localAddressV6 = "fe80::1033:2601/64";
      peerAddressV6 = "fe80::42:2601:36:1";
    };
    "50-wg4242420207" = {
      listenPort = 20207;
      peerEndpoint = "router.sea1.routedbits.com:51033";
      peerPublicKey = "/aY73VNAGQ7W+GersZUSO6PqHJV8nWKb12Op9EQzY3k=";
      localAddressV6 = "fe80::1033/64";
      peerAddressV6 = "fe80::0207";
    };
    "50-wg4242423914" = {
      listenPort = 23914;
      peerEndpoint = "us3.g-load.eu:21033";
      peerPublicKey = "sLbzTRr2gfLFb24NPzDOpy8j09Y6zI+a7NkeVMdVSR8=";
      localAddressV6 = "fe80::ade1/64";
      peerAddressV6 = "fe80::ade0";
    };
    "50-wg4242423035" = {
      listenPort = 23035;
      peerEndpoint = "usw1.dn42.lare.cc:21033";
      peerPublicKey = "Qd2XCotubH4QrQIdTZjYG4tFs57DqN7jawO9vGz+XWM=";
      localAddressV6 = "fe80::1033:3035/64";
      peerAddressV6 = "fe80::3035:132";
    };
  };
}
