{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  hyprlock = lib.getExe pkgs.hyprlock;
in
{
  imports = [
    ./hypridle.nix
    ./hyprlock.nix
  ];
  services.mako.enable = true;
  programs = {
    # imports = [ inputs.niri.homeModules.config ];
    niri.settings = {
      outputs = {
        "DP-1" = {
          mode = {
            width = 3440;
            height = 1440;
            refresh = 180.0;
          };
        };
        "HDMI-A-1".enable = false;
      };
      binds = {
        "Mod+D".action.spawn = "fuzzel";
        "Mod+T".action.spawn = "ghostty";
        "Mod+H".action.focus-column-left = { };
        "Mod+J".action.focus-window-down = { };
        "Mod+K".action.focus-window-up = { };
        "Mod+L".action.focus-column-right = { };
        "Mod+F".action.maximize-column = { };
        "Mod+Alt+L".action.spawn = hyprlock;
      };
      environment = {
        DISPLAY = ":0";
        NIXOS_OZONE_WL = "1";
      };
      spawn-at-startup =
        let
          withCommand = command-to-run: {
            command = [
              command-to-run
            ];
          };
        in
        [
          (withCommand (lib.getExe pkgs.hypridle))
          (withCommand (lib.getExe pkgs.xwayland-satellite))
        ];
    };
    fuzzel.enable = true;
    waybar = {
      enable = true;
      systemd.enable = true;
      settings = {
        mainBar.layer = "top";
      };
    };

  };
}
