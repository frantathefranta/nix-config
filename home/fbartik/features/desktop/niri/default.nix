{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

{
  # imports = [ inputs.niri.homeModules.config ];
  programs.niri.settings = {
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

    };
  };
  services.mako.enable = true;
  programs.swaylock.enable = true;
  programs.fuzzel.enable = true;
  programs.waybar.enable = true;
}
