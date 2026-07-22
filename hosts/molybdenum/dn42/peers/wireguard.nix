{ config, dn42Of, ... }:
let
  hostSubnet = config.meta.dn42.host.ipv6Subnet;
  peerSubnet = peer: (dn42Of peer).ipv6Subnet;
in
{
  services.custom-wireguard.interfaces = {
    # iBGP over OSPF link — peerHostname drives dn42Of resolution in bird module
    "ibgp_eu1" =
      let
        peer = "nix-vultr";
      in
      {
        listenPort = 24001;
        peerEndpoint = "eu1.dn42.franta.us:24001";
        peerPublicKey = "eu1Qgv9o0PSRXerUcYI7W+8Mb8LWg2NDVmnbmXWXUB0=";
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
        listenPort = 21033;
        peerEndpoint = "us2.dn42.franta.us:21033";
        peerPublicKey = "us2pm4+Wtwcyo6qTdUd/+QEAW2UJsQRe/UV1LBOzDwY=";
        peerAddressV6 = "fe80::${peerSubnet peer}:1033/128";
        localAddressV6 = "fe80::${hostSubnet}:1033/128";
        peerHostname = peer;
        latency = 5;
      };
    # "50-ospf_nix-vultr" = {
    #   listenPort = 24003;
    #   peerEndpoint = "eu1.dn42.franta.us:24001";
    #   peerPublicKey = "5SqQoNhZQuFY93I5Gbfks1xoOqOH4GfeSLkCcJ1v6WY=";
    #   localAddressV6 = "fe80::3:1033/128";
    #   peerAddressV6 = "fe80::300:1033/64";
    # };
    "ebgp_4242420454" = {
      listenPort = 20454;
      peerEndpoint = "dn42b.nedifinita.com:44280";
      peerPublicKey = "q9+7MHvWmWO18uZ0RfNNLNAgUWhqs+zA1zBoWv9r23U=";
      peerAddressV6 = "fe80::454:2/128";
      localAddressV6 = "fe80::1033:0454/64";
      latency = 4;
    };
    "ebgp_4242422601" = {
      listenPort = 22601;
      peerEndpoint = "dn42-us-nyc1.burble.com:21033";
      peerPublicKey = "38UOrMy2cr8fnn/tMn/uk2c6fE6JsdU0tjCQG4g1ey0=";
      localAddressV6 = "fe80::1033:2601/64";
      peerAddressV6 = "fe80::42:2601:29:1";
      latency = 4;
    };
    "ebgp_4242420207" = {
      listenPort = 20207;
      peerEndpoint = "router.chi1.routedbits.com:51033";
      peerPublicKey = "89xUzROs3l/KNPLxDTJz4l5aEH1cmLb22bNgChhRiQo=";
      localAddressV6 = "fe80::1033/64";
      peerAddressV6 = "fe80::0207";
      latency = 3;
    };
    "ebgp_4242423914" = {
      listenPort = 23914;
      peerEndpoint = "us2.g-load.eu:21033";
      peerPublicKey = "6Cylr9h1xFduAO+5nyXhFI1XJ0+Sw9jCpCDvcqErF1s=";
      localAddressV6 = "fe80::ade1/64";
      peerAddressV6 = "fe80::ade0";
      latency = 4;
    };
    "ebgp_4242423035" = {
      listenPort = 23035;
      peerEndpoint = "use2.dn42.lare.cc:21033";
      peerPublicKey = "AREskFoxP2cd6DXoJ7druDsiWKX+8TwrkQqfi4JxRRw=";
      localAddressV6 = "fe80::1033:3035/64";
      peerAddressV6 = "fe80::3035:137";
      latency = 3;
    };
    "ebgp_4242420253" = {
      listenPort = 20253;
      peerEndpoint = "lv.dn42.moe233.net:21033";
      peerPublicKey = "C3SneO68SmagisYQ3wi5tYI2R9g5xedKkB56Y7rtPUo=";
      localAddressV6 = "fe80::1033/64";
      peerAddressV6 = "fe80::0253";
      latency = 5;
    };
    "ebgp_4242421588" = {
      listenPort = 21588;
      peerEndpoint = "us-chi01.dn42.tech9.io:52581";
      peerPublicKey = "0kb8ffMcbx8oXZ3Ii5khOuCzmRqM2Cy0IslmrWtRGSk=";
      localAddressV6 = "fe80::100/64";
      peerAddressV6 = "fe80::1588";
      latency = 3;
    };
    "ebgp_4242422189" = {
      listenPort = 22189;
      peerEndpoint = "us-nyc.dn42.iedon.net:46161";
      peerPublicKey = "2Wmv10a9eVSni9nfZ7YPsyl3ZC5z7vHq0sTZGgk5WGo=";
      localAddressV6 = "fe80::1033/64";
      peerAddressV6 = "fe80::2189:124";
      latency = 4;
    };
    "ebgp_4242420401" = {
      listenPort = 20401;
      peerEndpoint = "useast01.dn42.markround.com:21033";
      peerPublicKey = "sTS3P+oL1rVAOB0bdVSm1TRKfIAwnQr/nHoArk6koik=";
      peerAddressV6 = "fe80::401/128";
      localAddressV6 = "fe80::1033:0401/128";
      latency = 3;
    };
    "ebgp_4242423999" = {
      listenPort = 23999;
      peerEndpoint = "yyz.node.cowgl.tech:31033";
      peerPublicKey = "XGIBvqoUOgb8IiLIWtO9JVNZc4SEpEAM1eWh26MtoRE=";
      peerAddressV6 = "fe80::5:3999/64";
      localAddressV6 = "fe80::3999:1033/64";
      latency = 2;
    };
    # Local BGP peer — not a DN42 peer, uses dedicated WG tunnel
    "50-wg_qotom" = {
      listenPort = 40001;
      peerEndpoint = "qotom.infra.franta.us:40001";
      peerPublicKey = "nVTI9kySAfJGAAEVjrVLLbWVESNVgl+n1d7RJzMyqRw=";
      localAddressV6 = "fe80::1033:6:5032/64";
      peerAddressV6 = "fe80::6:5032:1033";
    };
  };
}
