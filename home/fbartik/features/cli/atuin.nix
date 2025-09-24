{ config, ... }:
{
  programs.atuin = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      key_path = config.sops.secrets.atuin.path;
      update_check = false;
      sync_address = "https://atuin.franta.us";
    };
  };
  sops.secrets.atuin = {
    sopsFile = ../../secrets.yml;
  };
}
