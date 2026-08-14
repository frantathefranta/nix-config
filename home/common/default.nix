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
    inputs.direnv-instant.homeModules.direnv-instant
    ./atuin.nix
    ./bat.nix
    ./fzf.nix
    ./zoxide.nix
    ./packages.nix

    ./fish
  ]
  ++ (builtins.attrValues outputs.homeManagerModules);

  nix = {
    # On Darwin with Determinate Nix, disable home-manager's nix module
    # to avoid the activation script using a nixpkgs nix that doesn't
    # understand Determinate-specific settings (lazy-trees, eval-cores).
    # enable = !pkgs.stdenv.isDarwin;
    package = lib.mkDefault pkgs.nix;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "ca-derivations"
      ];
    };
  };

  sops = {
    age.keyFile = lib.mkDefault "${config.home.homeDirectory}/.config/sops/age/keys.txt";
  };

  # Enable home-manager and git
  programs.home-manager.enable = true;
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
