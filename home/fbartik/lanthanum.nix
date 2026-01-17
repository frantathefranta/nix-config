{ pkgs, ... }:
{
  imports = [
    ./global
    ./features/kubectl
    ./features/productivity
    ./features/games
    ./features/editor
    ./features/desktop/common
  ];
  home.packages = with pkgs; [
    unstable.prusa-slicer
    wpa_supplicant_gui
    winbox4
    prismlauncher
    f2fs-tools # Interacting with R2s filesystem
    rkdeveloptool # Interacting with Rockchip SBCs
  ];
  programs.ssh = {
    enable = true;
    matchBlocks = {
      nix-bastion = {
        identityAgent = "~/.1password/agent.sock";
        forwardAgent = true;
        hostname = "nix-bastion.infra.franta.us";
      };
    };
  };
  programs.ghostty = {
    enable = true;
    enableFishIntegration = true;
    systemd.enable = true;
    settings = {
      theme = "Earthsong";
      font-size = "10";
      initial-command = "tmux attach";
      # theme = "light:Belafonte Day,dark:Belafonte Night";
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
