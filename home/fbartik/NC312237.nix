{ pkgs, ... }:
{
  imports = [
    ./global
    ./features/productivity/aerc.nix
  ];
  home.packages = with pkgs; [
    nil
  ];
  sops.age.keyFile = null;
}
