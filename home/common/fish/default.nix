{ pkgs, ... }:
{
  imports = [
    ./bindings.nix
    ./shellabbr.nix
  ];
  home.packages = [ pkgs.bash-completion ];
  programs.fish.enable = true;
}
