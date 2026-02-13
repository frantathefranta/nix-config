{
  lib,
  pkgs,
  outputs,
  ...
}:
{
  imports = [
    ../../fbartik/features/cli
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
    username = "admin";
    homeDirectory = "/home/admin";
  };

  programs.neovim.enable = true;

  programs.home-manager.enable = true;
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "admin";
        email = "admin@nix-bastion";
      };
      init.defaultBranch = "main";
    };
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  home.stateVersion = "25.11";
}
