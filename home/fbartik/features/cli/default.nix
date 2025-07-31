{pkgs, ...}: {
  imports = [
    ./fish

    ./fzf.nix
    ./mise.nix
    ./tmux.nix
    ./zoxide.nix
    # ./bash.nix
    # ./bat.nix
    # ./direnv.nix
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
    comma # Install and run programs by sticking a , before them

    bc # Calculator
    bottom # System viewer
    btop # better top
    ncdu # TUI disk usage
    eza # Better ls
    file
    ripgrep # Better grep
    fd # Better find
    httpie # Better curl
    nmap
    jq # JSON pretty printer and manipulator
    sops
    screen
    # trekscii # Cute startrek cli printer
    timer # To help with my ADHD paralysis
    viddy # Better watch
    wget # I will simply not learn curl syntax for downloading files

    nixd # Nix LSP
    alejandra # Nix formatter
    nixfmt-rfc-style
    nvd # Differ
    nix-diff # Differ, more detailed
    nix-output-monitor
    nh # Nice wrapper for NixOS and HM
  ];
}
