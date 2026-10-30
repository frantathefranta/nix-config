{ pkgs, ... }:
{
  imports = [
    ./syncthing.nix
    ./github.nix
    ./forgejo.nix
    ./pass.nix
    ./wrtag.nix
    ./nix/nix-init.nix
  ];
  home.packages = with pkgs; [
    hcloud # Hetzner Cloud CLI
    zola
    age-plugin-yubikey
  ];
}
