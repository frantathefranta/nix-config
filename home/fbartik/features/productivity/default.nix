{ pkgs, ... }:
{
  imports = [
    ./syncthing.nix
    ./aerc.nix
    ./github.nix
  ];
  home.packages = with pkgs; [
    zola
  ];
}
