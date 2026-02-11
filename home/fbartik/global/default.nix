{
  config,
  lib,
  pkgs,
  inputs,
  outputs,
  ...
}:
{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
    inputs.snitch.homeManagerModules.snitch
    #inputs.impermanence.nixosModules.home-manager.impermanence
    ../features/cli
  ]
  ++ (builtins.attrValues outputs.homeManagerModules);

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
    homeDirectory = if pkgs.stdenv.isDarwin then "/Users/fbartik" else "/home/fbartik";
  };

  sops = {
    age.keyFile = lib.mkDefault "${config.home.homeDirectory}/.config/sops/age/keys.txt";
  };

  # Add stuff for your user as you see fit:
  programs.neovim.enable = true;
  programs.snitch = {
    enable = true;
    package = pkgs.unstable.snitch;
  };
  # home.packages = with pkgs; [
  #   ethtool
  #   gparted
  #   f2fs-tools
  # ];

  # Enable home-manager and git
  programs.home-manager.enable = true;
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "frantathefranta";
        email = "fb@franta.us";
      };
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
  systemd.user.startServices = lib.mkIf pkgs.stdenv.isLinux "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = lib.mkDefault "24.11";
}
