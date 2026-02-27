{ pkgs, ... }:
{
  services.caddy = {
    enable = true;
    globalConfig = ''
      acme_ca https://acme.burble.dn42/v1/dn42/acme/directory
      acme_ca_root ${pkgs.dn42-cacert}/etc/ssl/certs/dn42-ca.crt
    '';
    virtualHosts."lg.franta.dn42" = {
      extraConfig = ''
        reverse_proxy [fdb7:c21f:f30f::1]:5000
      '';
    };
    virtualHosts."franta.dn42" = {
      extraConfig = ''
        root * /var/www/public
        file_server browse
      '';
    };
  };
}
