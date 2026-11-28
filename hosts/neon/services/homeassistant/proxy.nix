{ config, pkgs, ... }:
let
  hostname = "hass.${config.networking.domain}";
in
{
  virtualisation.quadlet.containers.podman-caddy = {
    autoStart = false; # Started by the pod.
    unitConfig = {
      After = [ "acme-${hostname}.service" ];
      Requires = [ "acme-${hostname}.service" ];
    };
    serviceConfig.RestartSec = "2s"; # Allow IPv6 duplicate-address detection to finish.
    containerConfig = {
      name = "caddy";
      pod = config.virtualisation.quadlet.pods.home-assistant.ref;
      image = "docker.io/library/caddy:2.11.9";
      volumes = [
        "${pkgs.writeText "Caddyfile" ''
          {
            admin off
            auto_https disable_redirects
          }

          ${hostname} {
            bind 10.0.20.30 [2600:1702:6630:3fe1:10:0:20:30]
            tls /certs/fullchain.pem /certs/key.pem
            reverse_proxy 127.0.0.1:8123
          }
        ''}:/etc/caddy/Caddyfile:ro"
        "${config.security.acme.certs.${hostname}.directory}:/certs:ro"
      ];
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "fb@franta.us";
    certs.${hostname} = {
      dnsProvider = "cloudflare";
      dnsResolver = "1.1.1.1:53";
      environmentFile = config.sops.secrets."acme/cloudflare".path;
      reloadServices = [ "podman-caddy.service" ];
    };
  };

  sops.secrets."acme/cloudflare" = {
    sopsFile = ../../secrets.yaml;
  };

  networking.domains.subDomains.${hostname} = {
    a.data = [ "10.0.20.30" ];
    aaaa.data = [ "2600:1702:6630:3fe1:10:0:20:30" ];
  };
}
