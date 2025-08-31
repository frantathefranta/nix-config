{ pkgs, config, ... }:
let
  emacsPkg = pkgs.inputs.emacs-overlay;
  emacs =
    with pkgs;
    (emacsPackagesFor (
      if builtins.isNull config.monitors then emacsPkg.emacs-git else emacsPkg.emacs-git-pgtk
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
}
