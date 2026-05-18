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

  /*
        geofeed.csv
        172.23.234.17/32,US,US-OH,Columbus,43214,
        172.23.234.18/32,US,US-OR,Hillsboro,97124,
        172.23.234.19/32,CZ,CZ-10,Prague,10100,
        fdb7:c21f:f30f::/56,US,US-OH,Columbus,43214,
        fdb7:c21f:f30f:100:/56,US,US-OR,Hillsboro,97124, # https://www.hetzner.com/unternehmen/rechenzentrum/
        fdb7:c21f:f30f:200:/56,CZ,CZ-10,Prague,10100, # https://www.master.cz/datacentrum-praha/
  */
}
