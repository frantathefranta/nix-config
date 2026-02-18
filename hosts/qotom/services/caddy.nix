{
  services.caddy = {
    enable = true;
    globalConfig = ''
      auto_https off
    '';
    virtualHosts."qotom.infra.franta.us:80" = {
      extraConfig = ''
        root * /var/www
        file_server browse
      '';
    };
  };
  networking.firewall.interfaces.enp1s0.allowedTCPPorts = [
   80
  ];
}
