{ pkgs, ... }:
{
  imports = [
    ./syncthing.nix
    ./github.nix
    ./pass.nix
    ./nix/nix-init.nix
  ];
  home.packages = with pkgs; [
    hcloud # Hetzner Cloud CLI
    zola
    age-plugin-yubikey
  ];
}
