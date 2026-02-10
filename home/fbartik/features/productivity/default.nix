{ pkgs, ... }:
{
  imports = [
    ./syncthing.nix
    ./beets.nix
    ./aerc.nix
    ./github.nix
    ./pass.nix
  ];
  home.packages = with pkgs; [
    hcloud # Hetzner Cloud CLI
    zola
    age-plugin-yubikey
  ];
}
