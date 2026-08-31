# This file should be included when using hm standalone
{
  outputs,
  lib,
  inputs,
  ...
}:
let
  flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
in
{
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "ca-derivations"
      ];
      flake-registry = ""; # Disable global flake registry
    };
    registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
  };

  home.sessionVariables = {
    NIX_PATH = lib.concatStringsSep ":" (lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs);
  };

  nixpkgs.overlays = builtins.attrValues outputs.overlays ++ [
    inputs.emacs-overlay.overlays.default
    inputs.emacs-tramp-rpc.overlays.default
  ];
  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = _: true;
  };

}
