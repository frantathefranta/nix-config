{
  config,
  ...
}:

{
  security.acme = {
    acceptTerms = true;
    defaults.email = "fb@franta.us";
    certs."webdav.franta.us" = {
      dnsProvider = "cloudflare";
      dnsResolver = "1.1.1.1:53";
      environmentFile = config.sops.secrets."acme/cloudflare".path;
      group = config.services.webdav.group;
    };
  };

  services.webdav = {
    enable = true;
    settings = {
      address = "0.0.0.0";
      port = 8080;
      tls = true;
      cert = "${config.security.acme.certs."webdav.franta.us".directory}/cert.pem";
      key = "${config.security.acme.certs."webdav.franta.us".directory}/key.pem";
      directory = "/srv/public";
      permissions = "CRUD";
      users = [
        {
          username = "{env}ENV_USERNAME";
          password = "{env}ENV_PASSWORD";
        }
      ];
    };
    environmentFile = config.sops.secrets."webdav-env".path;
  };
  networking.nftables.firewall.rules.webdav = {
    from = [
      "local_interfaces"
      "wg"
    ];
    to = [ "fw" ];
    allowedTCPPorts = [ 8080 ];
  };
  sops.secrets."webdav-env".sopsFile = ../secrets.yaml;
}
