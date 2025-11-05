{ pkgs, ... }:
{
  imports = [
    ./firefox.nix
    ./font.nix
  ];
  home.packages = with pkgs; [
    discord
    plexamp
    lattice-diamond
  ];
}
