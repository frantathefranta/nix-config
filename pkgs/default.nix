{
  pkgs ? import <nixpkgs> { },
  ...
}:
rec {
  # Custom packages, that can be defined similarly to ones from nixpkgs
  # You can build them using 'nix build .#example'
  # example = pkgs.callPackage ./example { };
  conman = pkgs.callPackage ./conman { };
}
