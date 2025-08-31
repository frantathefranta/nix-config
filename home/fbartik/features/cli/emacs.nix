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
}
