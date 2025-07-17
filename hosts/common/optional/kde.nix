{
  services = {
    displayManager = {
      defaultSession = "plasma";
      sddm = {
        enable = true;
        wayland.enable = true;
      };
      desktopManager.plasma6.enable = true;
      xserver = {
        enable = true;
        videoDrivers = [ "nvidia" ];
      };
    };
  };
}
