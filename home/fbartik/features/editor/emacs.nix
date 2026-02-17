{ pkgs, config, lib, ... }:
let
  isDarwin = pkgs.stdenv.isDarwin;
  emacsBase =
    if isDarwin then pkgs.emacs
    else if (builtins.length config.monitors != 0) then pkgs.emacs-gtk
    else pkgs.emacs-nox;
  emacs =
    with pkgs;
    (emacsPackagesFor emacsBase)
    .emacsWithPackages
      (
        epkgs: with epkgs; [
          treesit-grammars.with-all-grammars
          vterm
          mu4e
          pbcopy
        ]
      );
in
{
  programs.emacs = {
    enable = true;
    package = emacs;
  };
  services.emacs = {
    enable = true;
    defaultEditor = true;
  };
  home.packages = with pkgs; [
    # For installing LSP servers
    nodePackages.npm
    ispell # Spelling
    # :tools editorconfig
    editorconfig-core-c # per-project style config
    # :tools lookup & :lang org +roam
    sqlite
    nil
    nixd # Nix LSP
    python3Minimal
    emacs-lsp-booster
    aporetic # fonts
  ] ++ lib.optionals (!isDarwin) [
    xclip
  ];
}
