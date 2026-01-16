{ lib, config, ... }:
{
  programs.atuin = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      # key_path = (lib.mkIf (config.sops.age.keyFile != null) config.sops.secrets.atuin.path);
      update_check = false;
      sync_address = "https://atuin.franta.us";
    };
  };
  # sops.secrets = lib.mkIf (builtins.hasAttr "key_path" config.programs.atuin.settings) {
  #   atuin.sopsFile = ../../secrets.yml;
  # };
}
