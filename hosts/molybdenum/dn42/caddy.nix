{
  services.caddy = {
    enable = true;
    extraConfig = ''
      lg.franta.dn42
      reverse_proxy :5000
    '';
  };
}
