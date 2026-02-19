{
  lib,
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./global
    ./features/editor
    ./features/productivity/aerc.nix
  ];
  home.packages = with pkgs; [
    symbola
  ];
  sops.age.keyFile = "${config.home.homeDirectory}/Library/Application Support/sops/age/keys.txt";
  sops.defaultSopsFile = ./NC312237-secrets.yaml;

  # sops-nix doesn't know about age-plugin-yubikey, so it has to be added to the launchd's $PATH
  launchd.agents.sops-nix.config.EnvironmentVariables."PATH" =
    lib.mkForce "/usr/bin:/bin:/usr/sbin:/sbin:${pkgs.age-plugin-yubikey}/bin";

  # My state version is 24.11, which defaults to linkApps. Changing it to copyApps which allows Spotlight to index the apps
  targets.darwin.linkApps.enable = false;
  targets.darwin.copyApps.enable = true;
}
