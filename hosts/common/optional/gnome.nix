{ lib, config, ... }:
{
  services.xserver = lib.mkIf (config.specialisation != {}) {
    enable = true;
    xkb.layout = "us";
    desktopManager.gnome.enable = true;
    displayManager.gdm.enable = true;
  };
}

