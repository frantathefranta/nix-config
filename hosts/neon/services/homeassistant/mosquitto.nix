{
  services.mosquitto = {
    enable = true;
    settings = {
      autosave_interval = 60;
    };
    listeners = [
      {
        port = 1883;
        settings.listener_allow_anonymous = true;
      }
    ];
  };
  networking.firewall.allowedTCPPorts = [ 1883 ];
}
