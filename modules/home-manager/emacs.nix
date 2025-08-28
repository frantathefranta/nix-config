{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
{
  options.modules.editors.emacs = {
    enable = true;
  };
  
#    nixpkgs.overlays = [
#      hey.inputs.emacs-overlay.overlays.default
#    ];

    config.home.packages = with pkgs; [
#      (mkLauncherEntry "Emacs (Debug Mode)" {
#        description = "Start Emacs in debug mode";
#        icon = "emacs";
#        exec = "${emacs}/bin/emacs --debug-init";
#      })

      ## Emacs itself
      binutils            # native-comp needs 'as', provided by this
      emacs               # HEAD + native-comp

      ## Doom dependencies
      git
      ripgrep
      gnutls              # for TLS connectivity

      ## Optional dependencies
      fd                  # faster projectile indexing
      imagemagick         # for image-dired
#      (lib.mkIf (config.programs.gnupg.agent.enable)
#        pinentry-emacs)   # in-emacs gnupg prompts
      zstd                # for undo-fu-session/undo-tree compression

      ## Module dependencies
      # :email mu4e
      mu
      isync
      # :checkers spell
      (aspellWithDicts (ds: with ds; [ en en-computers en-science ]))
      # :tools editorconfig
      editorconfig-core-c # per-project style config
      # :tools lookup & :lang org +roam
      sqlite
      # :lang cc
      clang-tools
      # :lang latex & :lang org (latex previews)
      texlive.combined.scheme-medium
      # :lang beancount
      beancount
      fava
      # :lang nix
      age
      nil
      # For installing LSP servers
      nodePackages.npm
    ];

#    environment.variables.PATH = [ "$XDG_CONFIG_HOME/emacs/bin" ];

#    modules.shell.zsh.rcFiles = [ "${hey.configDir}/emacs/aliases.zsh" ];

#    fonts.packages = [
#      (pkgs.nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })
#    ];
  
}
