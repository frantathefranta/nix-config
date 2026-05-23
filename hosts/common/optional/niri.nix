{
  config,
  lib,
  pkgs,
  ...
}:
let
  xwayland-satellite-package = pkgs.unstable.xwayland-satellite;
in
{
  programs.niri.enable = true;
  services.xserver.enable = true;
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${config.programs.niri.package}/bin/niri-session";
        user = "fbartik";
      };
    };
  };
  xdg = {
    portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      xdgOpenUsePortal = true;
    };
  };
  programs.xwayland = {
    enable = true;
    package = xwayland-satellite-package;
  };
  environment.systemPackages = [ xwayland-satellite-package ];
  services.xserver.exportConfiguration = true;
  environment.sessionVariables = {
    DISPLAY = ":0";
    NIXOS_OZONE_WL = "1";
    SDL_VIDEODRIVER = "wayland";
    # _JAVA_AWT_WM_NONREPARENTING = "1";
    CLUTTER_BACKEND = "wayland";
    WLR_RENDERER = "vulkan";
  };
}
