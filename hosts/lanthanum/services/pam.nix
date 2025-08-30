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
    services.kde = {
      u2fAuth = false;
    };
  };
  sops.secrets."u2f_keys" = {
    sopsFile = ../secrets.yaml;
    # If the file is not world-readable, kscreenlocker will not trigger the pam_u2f module
    mode = "0644";
  };
}
