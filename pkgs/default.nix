{
  pkgs ? import <nixpkgs> { },
  ...
}:
rec {
  # Custom packages, that can be defined similarly to ones from nixpkgs
  # You can build them using 'nix build .#example'
  # example = pkgs.callPackage ./example { };
  etBembo = pkgs.callPackage ./etbembo { };
  # akeyless = pkgs.callPackage ./akeyless-cli { };
  fake-hwclock = pkgs.callPackage ./fake-hwclock { };
  vep14xx-diags = pkgs.callPackage ./vep14xx-diags { };
  bird-lsp = pkgs.callPackage ./bird-lsp { };
  kubectl-passman = pkgs.callPackage ./kubectl-passman { };
  varroa = pkgs.callPackage ./varroa { };
  rtl8152-led-ctrl = pkgs.callPackage ./rtl8152-led-ctrl { };
  udpbroadcastrelay = pkgs.callPackage ./udpbroadcastrelay { };
  pi-acp = pkgs.callPackage ./pi-acp { };
  pi-coding-agent = pkgs.callPackage ./pi-coding-agent { };
  flate = pkgs.callPackage ./flate { };
  # ubootNanopiR2s = pkgs.callPackage ./uboot-nanopi-r2s { };
}
