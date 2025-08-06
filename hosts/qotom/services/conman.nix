{ config, ... }:
{
  services.conman = {
    enable = true;
    configFile = config.sops.secrets."conman.conf".path;
  };
  sops.secrets."conman.conf" = {
    sopsFile = ../secrets.yaml;
  };
}
