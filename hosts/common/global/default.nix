# This file (and the global directory) holds config that i use on all hosts
{
  inputs,
  outputs,
  pkgs,
  ...
}: {
  imports =
    [
      inputs.home-manager.nixosModules.home-manager
      # ./acme.nix
      # ./auto-upgrade.nix
      ./fish.nix
      ./locale.nix
      ./nh.nix
      ./nix.nix
      ./openssh.nix
      # ./optin-persistence.nix
      # ./podman.nix
      ./sops.nix
      # ./ssh-serve-store.nix
      # ./steam-hardware.nix
      # ./systemd-initrd.nix
      # ./tailscale.nix
      # ./gamemode.nix
      ./nix-ld.nix
      ./prometheus-node-exporter.nix
      # ./kdeconnect.nix
      # ./upower.nix
    ]
    ++ (builtins.attrValues outputs.nixosModules);

  home-manager.useGlobalPkgs = true;
  home-manager.extraSpecialArgs = {
    inherit inputs outputs;
  };

  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;
    config = {
      allowUnfree = true;
    };
  };

  # Fix for qt6 plugins
  # TODO: maybe upstream this?
  environment.profileRelativeSessionVariables = {
    QT_PLUGIN_PATH = ["/lib/qt-6/plugins"];
  };

  environment.systemPackages = with pkgs; [
    neovim
  ];

  # hardware.enableRedistributableFirmware = true;
  networking.domain = "infra.franta.us";

  # Increase open file limit for sudoers
  security.pam.loginLimits = [
    {
      domain = "@wheel";
      item = "nofile";
      type = "soft";
      value = "524288";
    }
    {
      domain = "@wheel";
      item = "nofile";
      type = "hard";
      value = "1048576";
    }
  ];
}
