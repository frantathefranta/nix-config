{ config, pkgs, ... }:
let
  hostname = "hass.${config.networking.domain}";
in
{
  virtualisation.oci-containers.containers.caddy = {
    image = "docker.io/library/caddy:2.11.9";
    autoStart = false; # Started and kept running by podman-home-assistant.
    networks = [ "container:home-assistant" ];
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

  systemd.services.podman-caddy = {
    after = [
      "acme-${hostname}.service"
      "podman-home-assistant.service"
    ];
    requires = [ "acme-${hostname}.service" ];
    bindsTo = [ "podman-home-assistant.service" ];
    partOf = [ "podman-home-assistant.service" ];
    serviceConfig.RestartSec = "2s"; # Allow IPv6 duplicate-address detection to finish.
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

  services.home-assistant.config.http = {
    use_x_forwarded_for = true;
    trusted_proxies = [ "127.0.0.1" ];
  };

  networking.domains.subDomains.${hostname} = {
    a.data = [ "10.0.20.30" ];
    aaaa.data = [ "2600:1702:6630:3fe1:10:0:20:30" ];
  };
}
