{ config, ... }:
{
  programs.atuin = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      key_path = config.sops.secrets.atuin.path;
    };
  };
  sops.secrets.atuin = {
    sopsFile = ../../secrets.yml;
  };
}
