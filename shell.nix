{
  pkgs ? import <nixpkgs> { },
  ...
}:
{
  default = pkgs.mkShell {
    NIX_CONFIG = "extra-experimental-features = nix-command flakes ca-derivations";
    nativeBuildInputs =
      with pkgs;
      [
        git
        sops
        ssh-to-age
        gnupg
        age
        opentofu
        tofu-ls
        just
        gum
        minijinja
        talosctl
        (octodns.withProviders (ps: [
          octodns-providers.bind
          octodns-providers.powerdns
          octodns-providers.desec
        ]))
      ]
      ++ lib.optionals stdenv.isLinux [
        home-manager
        nix
      ];
  };
}
