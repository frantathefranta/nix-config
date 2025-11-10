{ pkgs, ... }:
{
  imports = [
    ./fish

    ./atuin.nix
    ./fzf.nix
    ./mise.nix
    ./tmux.nix
    ./zoxide.nix
    # ./bash.nix
    # ./bat.nix
    ./direnv.nix
    # ./gh.nix
    # ./git.nix
    # ./gpg.nix
    # ./jujutsu.nix
    # ./lyrics.nix
    # ./nushell.nix
    # ./nix-index.nix
    # ./pfetch.nix
    ./ssh.nix
    # ./xpo.nix
    # ./jira.nix
  ];
  home.packages = with pkgs; [
    cachix # Cachix CLI client
    comma # Install and run programs by sticking a , before them
    unstable.devenv

    bc # Calculator
    bottom # System viewer
    btop # better top
    cyme # Modern lsusb
    dig # DNS
    doggo # Better DNS
    ncdu # TUI disk usage
    eza # Better ls
    file
    ripgrep # Better grep
    fd # Better find
    httpie # Better curl
    minijinja
    ipmitool # IPMI management
    unstable.managarr # Sonarr/Radarr TUI
    nmap
    jq # JSON pretty printer and manipulator
    sops
    screen
    s5cmd
    # trekscii # Cute startrek cli printer
    timer # To help with my ADHD paralysis
    viddy # Better watch
    wget # I will simply not learn curl syntax for downloading files

    mtr # traceroute replacement
    iperf3
    alejandra # Nix formatter
    nixfmt-rfc-style
    nvd # Differ
    nix-diff # Differ, more detailed
    nix-output-monitor
    unstable.nh # Nice wrapper for NixOS and HM

    # Rust
    cargo
  ];
}
