{
  services.custom-wireguard.interfaces = {
    # iBGP over OSPF links — peerHostname drives dn42Of resolution in bird module
    "ibgp_cmh" = {
      listenPort = 21033;
      peerEndpoint = "cmh.dn42.franta.us:21033";
      peerPublicKey = "3GAUz/+Q81eblrA78/LfkLs4X2CAsfnIHgw0R8LT9GE=";
      peerAddressV6 = "fe80::1033/128";
      localAddressV6 = "fe80::1:1033/128";
      peerAddressV4 = "169.254.1.3/31";
      localAddressV4 = "169.254.1.2/31";
      peerHostname = "molybdenum";
      latency = 4;
    };
    "ibgp_prg" = {
      listenPort = 24002;
      peerEndpoint = "prg.dn42.franta.us:24002";
      peerPublicKey = "I9U/GISDI42GHTv9CtDSmaoJTxzx1BQnrmFQcL/wazo=";
      peerAddressV6 = "fe80::2:1033/128";
      localAddressV6 = "fe80::1:1033/128";
      peerAddressV4 = "169.254.1.0/31";
      localAddressV4 = "169.254.1.1/31";
      peerHostname = "nix-vps-cz";
      latency = 6;
    };
    # eBGP peers
    "ebgp_4242420253" = {
      listenPort = 20253;
      peerEndpoint = "lv.dn42.moe233.net:21033";
      peerPublicKey = "C3SneO68SmagisYQ3wi5tYI2R9g5xedKkB56Y7rtPUo=";
      localAddressV6 = "fe80::1033/64";
      peerAddressV6 = "fe80::0253";
      latency = 4;
    };
    "ebgp_4242420454" = {
      listenPort = 20454;
      peerEndpoint = "dn42a.nedifinita.com:54876";
      peerPublicKey = "8EXT6zciVdil3Zg6dqB0YT2SssTh2OTKDeBBfrVGUkE=";
      peerAddressV6 = "fe80::454";
      localAddressV6 = "fe80::1033:0454/64";
      latency = 3;
    };
    "ebgp_4242421588" = {
      listenPort = 21588;
      peerEndpoint = "us-dal01.dn42.tech9.io:57500";
      peerPublicKey = "iEZ71NPZge6wHKb6q4o2cvCopZ7PBDqn/b3FO56+Hkc=";
      peerAddressV6 = "fe80::1588/64";
      localAddressV6 = "fe80::100";
      latency = 4;
    };
    "ebgp_4242422601" = {
      listenPort = 22601;
      peerEndpoint = "dn42-us-lax1.burble.com:21033";
      peerPublicKey = "WqJjS3x+L802AuMvpfeiVZNUCm1WxbYd+kBPx+2suDs=";
      localAddressV6 = "fe80::1033:2601/64";
      peerAddressV6 = "fe80::42:2601:2a:1";
      latency = 3;
    };
    "ebgp_4242420207" = {
      listenPort = 20207;
      peerEndpoint = "router.sea1.routedbits.com:51033";
      peerPublicKey = "/aY73VNAGQ7W+GersZUSO6PqHJV8nWKb12Op9EQzY3k=";
      localAddressV6 = "fe80::1033/64";
      peerAddressV6 = "fe80::0207";
      latency = 2;
    };
    "ebgp_4242423914" = {
      listenPort = 23914;
      peerEndpoint = "us3.g-load.eu:21033";
      peerPublicKey = "sLbzTRr2gfLFb24NPzDOpy8j09Y6zI+a7NkeVMdVSR8=";
      localAddressV6 = "fe80::ade1/64";
      peerAddressV6 = "fe80::ade0";
      latency = 4;
    };
    "ebgp_4242423035" = {
      listenPort = 23035;
      peerEndpoint = "usw1.dn42.lare.cc:21033";
      peerPublicKey = "Qd2XCotubH4QrQIdTZjYG4tFs57DqN7jawO9vGz+XWM=";
      localAddressV6 = "fe80::1033:3035/64";
      peerAddressV6 = "fe80::3035:132";
      latency = 4;
    };
    "ebgp_4242423088" = {
      listenPort = 23088;
      peerEndpoint = "v6.sjc1-us.dn42.6700.cc:21033";
      peerPublicKey = "G/ggwlVSy5jKWFlJM01hxcWnL8VDXsD5EXZ/S47SmhM=";
      peerAddressV6 = "fe80::3088:191/128";
      localAddressV6 = "fe80::abcd/128";
      latency = 3;
    };
  };
}
