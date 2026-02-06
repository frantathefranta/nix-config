{ lib, ... }:
{
  imports = [
    ../optional/1password.nix
  ];
  # Sound via pipewire
  security.rtkit.enable = true;
  services.pipewire = {
    enable = lib.mkDefault true;
    alsa.enable = lib.mkDefault true;
    alsa.support32Bit = lib.mkDefault true;
    pulse.enable = lib.mkDefault true;
  };

  # Hardware support
  hardware = {
    bluetooth.enable = lib.mkDefault true;
    enableRedistributableFirmware = lib.mkDefault true;
  };

  # Printing
  services.printing.enable = lib.mkDefault true;

  # Graphical boot
  boot.plymouth.enable = lib.mkDefault true;
}
