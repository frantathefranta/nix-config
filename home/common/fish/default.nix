{ pkgs, ... }:
{
  imports = [
    ./bindings.nix
    ./shellabbr.nix
  ];
  home.packages = [ pkgs.bash-completion ];
  programs.fish.enable = true;
  programs.fish.shellInit = ''
    fish_config theme save default-rgb
  '';
}
