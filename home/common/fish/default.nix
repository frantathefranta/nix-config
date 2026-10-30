{ pkgs, ... }:
{
  imports = [
    ./bindings.nix
    ./shellabbr.nix
  ];
  home.packages = [ pkgs.bash-completion ];
  programs.fish.enable = true;
  programs.fish.interactiveShellInit = ''
    fish_config theme choose default-rgb
  '';
}
