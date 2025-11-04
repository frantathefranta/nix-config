{
  config,
  tunnel,
  ospf,
  ...
}:

{
  routed-bits =
    tunnel "{ 20207 }" config.sops.secrets.routed-bits.path
      "{ 89xUzROs3l/KNPLxDTJz4l5aEH1cmLb22bNgChhRiQo= }"
      "{router.chi1.routedbits.com:51033}"
      "{wg4242420207}"
      "{}"
      "{fe80::1033/64}"
      "{}"
      "{fe80::0207/64}";
}
