{
  imports = [
    ./wireless.nix
    ./virtualisation.nix
  ];
  services.flatpak.enable = true;
}
