{ pkgs, ... }:
{
  # imports = [ ./global ];
  home.packages = [
    pkgs.zola
  ];
  home.stateVersion = "24.11";
}
