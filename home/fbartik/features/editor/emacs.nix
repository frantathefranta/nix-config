{ pkgs, config, ... }:
let
  emacsPkg = pkgs.inputs.emacs-overlay;
  emacs =
    with pkgs;
    (emacsPackagesFor (
      if (builtins.length config.monitors != 0) then emacsPkg.emacs-git-pgtk else emacsPkg.emacs-git
    )).emacsWithPackages
      (
        epkgs: with epkgs; [
          treesit-grammars.with-all-grammars
          vterm
          mu4e
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
    xclip
    python3Minimal
  ];
}
