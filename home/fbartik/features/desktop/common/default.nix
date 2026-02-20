{ pkgs, ... }:
{
  imports = [
    ./firefox.nix
    ./font.nix
    ./mail.nix
  ];
  home.packages = with pkgs; [
    discord
    plexamp
  ];
}
