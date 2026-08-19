{ pkgs, inputs, ... }:

{
  programs.nix-init = {
    enable = true;
    package = inputs.nix-init.packages.${pkgs.stdenv.hostPlatform.system}.default;
    settings = {
      maintainers = ["frantathefranta"];
      nixpkgs = "<nixpkgs>";
      commit = true;
    };
  };
}
