{ pkgs, ... }:

{
  security.pki.certificateFiles = [ "${pkgs.dn42-cacert}/etc/ssl/certs/dn42-ca.crt" ];
  services.resolved.dnsDelegates."dn42".Delegate = {
    DNS = "fdb7:c21f:f30f:53::";
    Domains = [
      "~dn42"
      "~d.f.ip6.arpa"
    ];
  };
}
