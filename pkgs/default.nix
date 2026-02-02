{
  pkgs ? import <nixpkgs> { },
  ...
}:
rec {
  # Custom packages, that can be defined similarly to ones from nixpkgs
  # You can build them using 'nix build .#example'
  # example = pkgs.callPackage ./example { };
  # conman = pkgs.callPackage ./conman { };
  etBembo = pkgs.callPackage ./etbembo { };
  akeyless = pkgs.callPackage ./akeyless-cli { };
  fake-hwclock = pkgs.callPackage ./fake-hwclock {  };
  bird-lg-custom = pkgs.callPackage ./bird-lg {  };
  # rtl8152-led-ctrl = pkgs.callPackage ./rtl8152-led-ctrl { };
  # ubootNanopiR2s = pkgs.callPackage ./uboot-nanopi-r2s { };
}
