{
  inputs,
  lib,
  ...
}:
let
  flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
in
{
  nix = {
    settings = {
      extra-substituters = lib.mkAfter [
        "https://frantathefranta.cachix.org"
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://eh5.cachix.org"
      ];
      extra-trusted-public-keys = lib.mkAfter [
        "eh5.cachix.org-1:pNWZ2OMjQ8RYKTbMsiU/AjztyyC8SwvxKOf6teMScKQ="
      ];
      trusted-users = [
        "root"
        "@wheel"
      ];
      # Optimizes store during each build
      auto-optimise-store = lib.mkDefault true;
      experimental-features = [
        "nix-command"
        "flakes"
        "ca-derivations"
      ];
      warn-dirty = false;
      system-features = [
        "kvm"
        "big-parallel"
        "nixos-test"
      ];
      flake-registry = ""; # Disable global flake registry
    };
    # Pin each flake input (including nixpkgs) in the registry and NIX_PATH
    # so that ad-hoc commands (nix shell, nix build, nix-shell -p,
    # import <name>) resolve to the same revisions the system was built from.
    registry = lib.mapAttrs (_: flake: { inherit flake; }) (lib.filterAttrs (n: _: n != "nixpkgs") flakeInputs);
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
  };
}
