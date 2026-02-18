{
  services.caddy = {
    enable = false;
    virtualHosts."qotom.infra.franta.us" = {
      extraConfig = ''
        root * /var/www
        file_server
      '';
    };
  };
}
