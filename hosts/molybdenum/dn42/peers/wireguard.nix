{
  services.custom-wireguard.interfaces = {
    "50-ospf_nix-vps-cz" = {
      listenPort = 24001;
      peerEndpoint = "prg.dn42.franta.us:24001";
      peerPublicKey = "NDQyX3K9piwzVi30GDqudZLjgDsAZsBIndtqI4I5k2A=";
      localAddressV6 = "fe80::1033";
      peerAddressV6 = "fe80::2:1033/64";
      isOSPF = true;
      peerAddressV4 = "169.254.2.0/31";
      localAddressV4 = "169.254.2.1/31";
    };
    "50-wg4242420454" = {
      listenPort = 20454;
      peerEndpoint = "dn42b.nedifinita.com:55965";
      peerPublicKey = "W4yTKYVWin9xkSDgGRKA6DlGADOMZADGR6OaJZgV1UI=";
      peerAddressV6 = "fe80::454:2";
      localAddressV6 = "fe80::1033:0454/64";
    };
    "50-wg4242422601" = {
      listenPort = 22601;
      peerEndpoint = "dn42-us-nyc1.burble.com:21033";
      peerPublicKey = "38UOrMy2cr8fnn/tMn/uk2c6fE6JsdU0tjCQG4g1ey0=";
      localAddressV6 = "fe80::1033:2601/64";
      peerAddressV6 = "fe80::42:2601:29:1";
    };
    "50-wg4242420207" = {
      listenPort = 20207;
      peerEndpoint = "router.chi1.routedbits.com:51033";
      peerPublicKey = "89xUzROs3l/KNPLxDTJz4l5aEH1cmLb22bNgChhRiQo=";
      localAddressV6 = "fe80::1033/64";
      peerAddressV6 = "fe80::0207";
    };
    "50-wg4242423914" = {
      listenPort = 23914;
      peerEndpoint = "us2.g-load.eu:21033";
      peerPublicKey = "6Cylr9h1xFduAO+5nyXhFI1XJ0+Sw9jCpCDvcqErF1s=";
      localAddressV6 = "fe80::ade1/64";
      peerAddressV6 = "fe80::ade0";
    };
    "50-wg4242423035" = {
      listenPort = 23035;
      peerEndpoint = "use2.dn42.lare.cc:21033";
      peerPublicKey = "AREskFoxP2cd6DXoJ7druDsiWKX+8TwrkQqfi4JxRRw=";
      localAddressV6 = "fe80::1033:3035/64";
      peerAddressV6 = "fe80::3035:137";
    };
    "50-wg4242420253" = {
      listenPort = 20253;
      peerEndpoint = "lv.dn42.moe233.net:21033";
      peerPublicKey = "C3SneO68SmagisYQ3wi5tYI2R9g5xedKkB56Y7rtPUo=";
      localAddressV6 = "fe80::1033/64";
      peerAddressV6 = "fe80::0253";
    };
    "50-wg4242421588" = {
      listenPort = 21588;
      peerEndpoint = "us-chi01.dn42.tech9.io:52581";
      peerPublicKey = "0kb8ffMcbx8oXZ3Ii5khOuCzmRqM2Cy0IslmrWtRGSk=";
      localAddressV6 = "fe80::100/64";
      peerAddressV6 = "fe80::1588";
    };
    "50-wg4242422189" = {
      listenPort = 22189;
      peerEndpoint = "us-nyc.dn42.iedon.net:46161";
      peerPublicKey = "2Wmv10a9eVSni9nfZ7YPsyl3ZC5z7vHq0sTZGgk5WGo=";
      localAddressV6 = "fe80::1033/64";
      peerAddressV6 = "fe80::2189:124";
    };
    "50-wg_qotom" = {
      listenPort = 40001;
      peerEndpoint = "qotom.infra.franta.us:40001";
      peerPublicKey = "nVTI9kySAfJGAAEVjrVLLbWVESNVgl+n1d7RJzMyqRw=";
      localAddressV6 = "fe80::1033:6:5032/64";
      peerAddressV6 = "fe80::6:5032:1033";
    };
  };
}
