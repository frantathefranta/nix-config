{ pkgs, ... }: {
  programs.direnv = {
    enable = true;
    # enableFishIntegration = false;
    nix-direnv.enable = true;
    # nixpkgs PR#475992 added postInstall = "rm -rf $out/share/fish" but
    # direnv sets installPhase as a variable, so Nix evals it directly and
    # never calls runHook postInstall. Append the rm to installPhase itself.
    package = pkgs.direnv.overrideAttrs (old: {
      installPhase = old.installPhase + ''
        rm -rf "$out/share/fish"
      '';
    });
  };
  programs.direnv-instant = {
    enable = true;
  };
}
