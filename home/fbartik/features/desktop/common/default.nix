{ pkgs, ... }:
{
  imports = [
    ./firefox.nix
    ./font.nix
    ./aerc.nix
  ];
  home.packages = with pkgs; [
    discord
    plexamp
  ];
}
