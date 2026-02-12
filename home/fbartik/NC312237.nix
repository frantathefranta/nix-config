{ config, pkgs, ... }:
{
  imports = [
    ./global
    ./features/productivity/aerc.nix
  ];
  home.packages = with pkgs; [
    nil
  ];
  sops.age.keyFile = "${config.home.homeDirectory}/Library/Application Support/sops/age/keys.txt";
  sops.defaultSopsFile = ./NC312237-secrets.yaml;
}
