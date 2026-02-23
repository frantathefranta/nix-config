{ pkgs, ... }:
{
  imports = [
    ./global
    ./features/kubectl
    ./features/productivity
    ./features/editor
    ./features/desktop/common
    ./features/productivity/claude-code.nix
  ];
  home.packages = with pkgs; [
    wpa_supplicant_gui
    winbox4
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
  # systemd.user.services.sops-nix.Service.Environment = [ "PATH=${pkgs.age-plugin-1p}/bin" ];
  monitors = [
    {
      name = "eDP-1";
      width = 1920;
      height = 1080;
      workspace = "1";
      primary = true;
    }
  ];
}
