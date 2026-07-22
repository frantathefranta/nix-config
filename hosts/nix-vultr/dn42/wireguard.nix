{
  config,
  dn42Of,
  ...
}:

let
  hostSubnet = config.meta.dn42.host.ipv6Subnet;
  peerSubnet = peer: (dn42Of peer).ipv6Subnet;
in
{
  services.custom-wireguard.interfaces = {
    "ibgp_us1" =
      let
        peer = "molybdenum";
      in
      {
        listenPort = 24001;
        peerEndpoint = "us1.dn42.franta.us:24001";
        peerPublicKey = "us1pY2jjw6+m7zP6xYAplrpJj9SzSXKNgq5SquSNtlo=";
        peerAddressV6 = "fe80::${peerSubnet peer}:1033/128";
        localAddressV6 = "fe80::${hostSubnet}:1033/128";
        peerHostname = peer;
        latency = 5;
      };
    "ibgp_us2" =
      let
        peer = "nix-hetzner";
      in
      {
        listenPort = 24002;
        peerEndpoint = "us2.dn42.franta.us:24002";
        peerPublicKey = "us2Yc4lisi5eM9yJ+3bBADZs5/wIR7q/PPTtzCDCnXw=";
        peerAddressV6 = "fe80::${peerSubnet peer}:1033/128";
        localAddressV6 = "fe80::${hostSubnet}:1033/128";
        peerHostname = peer;
        latency = 5;
      };
    "ebgp_4242423914" = {
      listenPort = 23914;
      peerEndpoint = "de2.g-load.eu:20003";
      peerPublicKey = "B1xSG/XTJRLd+GrWDsB06BqnIq8Xud93YVh/LYYYtUY=";
      localAddressV6 = "fe80::ade1/64";
      peerAddressV6 = "fe80::ade0";
    };
    "ebgp_4242420207" = {
      listenPort = 20207;
      peerEndpoint = "router.fra1.routedbits.com:51033";
      peerPublicKey = "FIk95vqIJxf2ZH750lsV1EybfeC9+V8Bnhn8YWPy/l8=";
      localAddressV6 = "fe80::1033/128";
      peerAddressV6 = "fe80::0207/128";
    };
    "ebgp_4242420253" = {
      listenPort = 20253;
      peerEndpoint = "ams.dn42.moe233.net:21033";
      peerPublicKey = "vRRfNnGL7jpKGBJjLZg612vHQulDOtICkgXCC++1+2g=";
      localAddressV6 = "fe80::1033/64";
      peerAddressV6 = "fe80::0253";
    };
    "ebgp_4242420263" = {
      listenPort = 20263;
      peerEndpoint = "fr-par1.flap42.eu:52029";
      peerPublicKey = "/kwo9FiQRtgNyhMARTW9SvyvXIN7I7LfoICTytHjfA4=";
      peerAddressV6 = "fe80::0263/128";
      localAddressV6 = "fe80::1033/128";
    };
    "ebgp_4242422884" = {
      listenPort = 22884;
      peerEndpoint = "dn42-de-fra01.datenfass.com:21033";
      peerPublicKey = "kXxGLbuklKYCUhVS30DJKvn/hv2tgHwweGjd21VoqRQ=";
      peerAddressV6 = "fe80::2884/128";
      localAddressV6 = "fe80::1033:2884/128";
    };
    "ebgp_4242423088" = {
      listenPort = 23088;
      peerEndpoint = "v6.ams1-nl.dn42.6700.cc:21033";
      peerPublicKey = "AgXewx4akBG9QI9ClbJMcflmDY1rsdOslRTI/CL4PHk=";
      peerAddressV6 = "fe80::3088:194/128";
      localAddressV6 = "fe80::abcd/128";
    };
    "ebgp_4242420401" = {
      listenPort = 20401;
      peerEndpoint = "de01.dn42.markround.com:21033";
      peerPublicKey = "ZPwzKog7ii0RVJsvRKRz2WdFHU0FWujMKDVqk9UKbF0=";
      peerAddressV6 = "fe80::401/128";
      localAddressV6 = "fe80::1033:0401/128";
    };
    "ebgp_4242423999" = {
      listenPort = 23999;
      peerEndpoint = "fra.node.cowgl.tech:31033";
      peerPublicKey = "sHPUV74X+hqUK5wFj3m5kCga0rlPCxImUBwZ/oLiEn4=";
      peerAddressV6 = "fe80::3:3999/64";
      localAddressV6 = "fe80::3999:1033/64";
      latency = 2;
    };
    "ebgp_4242422213" = {
      listenPort = 22213;
      peerEndpoint = "de1.115411.xyz:21033";
      peerPublicKey = "73FCWf+KvJ+bUHxJ6mpbEzmcELImdasIMB64zCf3sBQ=";
      peerAddressV6 = "fe80::2213/128";
      localAddressV6 = "fe80::2213:1033/128";
      latency = 3;
    };
  };
}
