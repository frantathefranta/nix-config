  {pkgs ? import <nixpkgs> {}, ...}: {
  default = pkgs.mkShell {
    NIX_CONFIG = "extra-experimental-features = nix-command flakes ca-derivations";
    nativeBuildInputs = with pkgs; [
      nix
      git

      sops
      ssh-to-age
      gnupg
      age
    ] ++ lib.optionals stdenv.isLinux [
      home-manager
    ];
  };
}
