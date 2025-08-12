{ pkgs, }:
{
  imports = [
    ./sunshine.nix
  ];
  services.udev.packages = with pkgs; [
    vial
    via
  ];
}
