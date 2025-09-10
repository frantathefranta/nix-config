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
  programs.ssh = {
    enable = true;
    matchBlocks = {
      nix-bastion = {
        identityAgent = "~/.1password/agent.sock";
        forwardAgent = true;
        hostname = "nix-bastion.franta.us";
      };
    };
  };
  # emacs.enable = true;
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
