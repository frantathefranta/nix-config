{
  lib,
  pkgs,
  inputs,
  outputs,
  ...
}:
{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
    #inputs.impermanence.nixosModules.home-manager.impermanence
    ../features/cli
    # ./steam-hardware.nix
    #../features/helix
  ] ++ (builtins.attrValues outputs.homeManagerModules);

  nix = {
    package = lib.mkDefault pkgs.nix;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "ca-derivations"
      ];
      warn-dirty = false;
    };
  };

  home = {
    username = "fbartik";
    homeDirectory = "/home/fbartik";
  };

  sops = {
    age.keyFile = "/home/fbartik/.config/sops/age/keys.txt";
  };

  # Add stuff for your user as you see fit:
  programs.neovim.enable = true;
  home.packages = with pkgs; [
    ethtool
  ];

  # Enable home-manager and git
  programs.home-manager.enable = true;
  programs.git = {
    enable = true;
    userName = "frantathefranta";
    userEmail = "fb@franta.us";
    extraConfig = {
      init.defaultBranch = "main";
      # fish takes these options and adds them to the prompt
      bash = {
        showInformativeStatus = true;
        showDirtyState = true;
        showUntrackedFiles = true;
      };
    };
  };
  services.home-manager.autoExpire = {
    enable = true;
    frequency = "weekly";
    timestamp = "-7 days";
  };
  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "24.11";
}
