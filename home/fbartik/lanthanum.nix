{ pkgs, ... }:
{
  imports = [
    ./global
    ./features/kubectl
    ./features/productivity
    ./features/games
    ./features/desktop/common
  ];
  home.packages = [
    pkgs.unstable.prusa-slicer
  ];
  monitors = [
    {
      name = "DP-1";
      width = 3440;
      height = 1440;
      workspace = "1";
      primary = true;
    }
  ];
}
