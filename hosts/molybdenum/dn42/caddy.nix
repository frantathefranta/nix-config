{ pkgs, ... }:
{
  services.caddy = {
    enable = true;
    globalConfig = ''
      acme_ca https://acme.burble.dn42/v1/dn42/acme/directory
      acme_ca_root ${pkgs.dn42-cacert}/etc/ssl/certs/dn42-ca.crt
    '';
    extraConfig = ''
      lg.franta.dn42 {
        reverse_proxy [fdb7:c21f:f30f::1]:5000
      }
    '';
  };
}
/*
  When implementing 2 domains with 2 ACME servers, it should look like this:
  domain1.com {
      tls {
          issuer acme {
              ca https://acme-ca-1.example.com/directory
              trusted_roots_pem_files /path/to/root-ca.crt
          }
      }
      reverse_proxy 192.168.1.100:8080
  }

  domain2.com {
      tls {
          issuer acme {
              ca https://acme-ca-2.example.com/directory
              trusted_roots_pem_files /path/to/other-ca-root.crt
          }
      }
      reverse_proxy 192.168.1.100:8080
  }
*/
