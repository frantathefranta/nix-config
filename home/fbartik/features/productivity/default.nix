{ pkgs, ... }:
{
  imports = [
    ./syncthing.nix
    ./aerc.nix
    ./github.nix
  ];
  home.packages = with pkgs; [
    hcloud # Hetzner Cloud CLI
    zola
  ];
}
