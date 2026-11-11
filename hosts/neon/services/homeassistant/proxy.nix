{ config, ... }:
let
  hostname = "hass.${config.networking.domain}";
in
{
  services.caddy = {
    enable = true;
    openFirewall = true;
    virtualHosts.${hostname} = {
      useACMEHost = hostname;
      extraConfig = ''
        reverse_proxy 127.0.0.1:8123
      '';
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "fb@franta.us";
    certs.${hostname} = {
      dnsProvider = "cloudflare";
      dnsResolver = "1.1.1.1:53";
      environmentFile = config.sops.secrets."acme/cloudflare".path;
    };
  };

  sops.secrets."acme/cloudflare" = {
    sopsFile = ../../secrets.yaml;
  };

  services.home-assistant.config.http = {
    use_x_forwarded_for = true;
    trusted_proxies = [ "127.0.0.1" ];
  };

  networking.domains.subDomains.${hostname}.cname.data = config.networking.hostName;
}
