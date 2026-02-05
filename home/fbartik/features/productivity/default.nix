{ pkgs, ... }:
{
  imports = [
    ./syncthing.nix
    ./beets.nix
    ./aerc.nix
    ./github.nix
  ];
  home.packages = with pkgs; [
    hcloud # Hetzner Cloud CLI
    zola
  ];
}
