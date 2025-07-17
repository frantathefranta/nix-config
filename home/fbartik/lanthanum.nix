{ ... }:
{
  imports = [
    ./global
    ./features/kubectl
    ./features/productivity
    ./features/games
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
