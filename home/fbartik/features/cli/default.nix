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
      comma # Install and run programs by sticking a , before them

      bc # Calculator
      bottom # System viewer
      caligula # For image flashing
      cyme # Modern lsusb
      ncdu # TUI disk usage
      eza # Better ls
      file
      minijinja
      managarr # Sonarr/Radarr TUI
      sops
      screen
      s5cmd
      timer # To help with my ADHD paralysis

      alejandra # Nix formatter
      nixfmt
      nvd # Differ
      nix-diff # Differ, more detailed
      nix-output-monitor
      # nh # Nice wrapper for NixOS and HM
      snitch

      # Rust
      cargo
    ]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
      ipmitool # IPMI management
    ];
}
