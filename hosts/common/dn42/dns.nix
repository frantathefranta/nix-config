{
  config,
  lib,
  ...
}:

{
  services.resolved.dnsDelegates."dn42".Delegate = lib.mkIf (!config.services.bind.enable) {
    DNS = "fdb7:c21f:f30f:53::";
    Domains = [
      "~dn42"
      "~d.f.ip6.arpa"
    ];
  };
}
