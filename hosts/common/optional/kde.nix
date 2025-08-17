{ pkgs, ... }:
{
  services = {
    displayManager = {
      defaultSession = "plasma";
      sddm = {
        enable = true;
        wayland.enable = true;
      };
    };
    desktopManager.plasma6.enable = true;
    xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ];
    };
  };
  environment.systemPackages = with pkgs.kdePackages; [
    kcalc
    discover # Optional: Install if you use Flatpak or fwupd firmware update sevice
    ksystemlog
    sddm-kcm # Configuration module for SDDM
    krohnkite # Dynamic tiling manager
  ];
}
