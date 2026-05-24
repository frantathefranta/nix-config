{
  config,
  lib,
  pkgs,
  ...
}:
# let
#   # inherit (lib) mkIf;
#   # cfg = config.home-config.desktop;
# in
{
  home.packages = (
    with pkgs;
    [
      hypridle
    ]
  );

  home.file.".config/hypr/hypridle.conf" = {
    text =
      let
        hyprlock = "${pkgs.hyprlock}/bin/hyprlock";
        loginctl = "${pkgs.systemd}/bin/loginctl";
        hyprctl = "${pkgs.hyprland}/bin/hyprctl"; # FIX THIS ?
        systemctl = "${pkgs.systemd}/bin/systemctl";
      in
      ''
        $lock_cmd = ${hyprlock}
        $before_sleep_cmd = ${loginctl} lock-session
        $after_sleep_cmd = ${hyprctl}

        general {
            lock_cmd = $lock_cmd
            before_sleep_cmd = $before_sleep_cmd
            after_sleep_cmd = $after_sleep_cmd
        }

        listener {
            timeout = 120
            on-timeout = ${hyprlock}
        }

        listener {
            timeout = 90
            on-timeout =  ${hyprctl} dispatch dpms off
            on-resume =  ${hyprctl} dispatch dpms on
        }

        listener {
            timeout = 300
            on-timeout = ${systemctl} suspend
        }
      '';
  };
}
