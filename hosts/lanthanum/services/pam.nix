{ config, ... }:
{
  security.pam = {
    u2f = {
      enable = true;
      settings = {
        authfile = config.sops.secrets."u2f_keys".path;
        cue = true;
      };
    };
  };
  sops.secrets."u2f_keys" = {
    sopsFile = ../secrets.yaml;
  };
}
