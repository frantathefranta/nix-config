{
  services.caddy = {
    virtualHosts."qotom.franta.us" = {
      extraConfig = ''
        root * /var/www
        file_server
      '';
    };
  };
}
