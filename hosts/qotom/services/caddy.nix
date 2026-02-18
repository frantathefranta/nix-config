{
  services.caddy = {
    enable = true;
    virtualHosts."qotom.infra.franta.us" = {
      extraConfig = ''
        root * /var/www
        file_server
      '';
    };
  };
}
