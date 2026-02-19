{ pkgs, ... }:
{
  imports = [
    ./syncthing.nix
    ./github.nix
    ./beets.nix
    ./pass.nix
  ];
  home.packages = with pkgs; [
    hcloud # Hetzner Cloud CLI
    zola
    age-plugin-yubikey
  ];
}
