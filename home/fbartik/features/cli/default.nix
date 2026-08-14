{ pkgs, lib, ... }:
{
  imports = [
    ./fish

    ./tmux.nix
    ./direnv.nix
    ./gh.nix
    ./git.nix
    ./gpg.nix
    ./nix-index.nix
    ./ssh.nix
  ];
  home.packages =
    with pkgs;
    [
      cachix # Cachix CLI client
      comma # Install and run programs by sticking a , before them
      devenv

      bc # Calculator
      bottom # System viewer
      cyme # Modern lsusb
      ncdu # TUI disk usage
      eza # Better ls
      file
      minijinja
      unstable.managarr # Sonarr/Radarr TUI
      sops
      screen
      s5cmd
      timer # To help with my ADHD paralysis

      alejandra # Nix formatter
      nixfmt
      nvd # Differ
      nix-diff # Differ, more detailed
      nix-output-monitor
      # unstable.nh # Nice wrapper for NixOS and HM
      unstable.snitch # TODO: Change to stable when 26.05 is

      # Rust
      cargo
    ]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
      ipmitool # IPMI management
    ];
}
