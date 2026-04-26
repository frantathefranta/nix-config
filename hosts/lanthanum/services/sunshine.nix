{ pkgs, ... }:
let
  kscreen-doctor = "${pkgs.kdePackages.libkscreen}/bin/kscreen-doctor";
  # Wayland needs sudo -u $USER (https://wiki.nixos.org/wiki/Sunshine#Running_Steam_Big_Picture_on_Wayland)
  setsid = "sudo -u fbartik ${pkgs.util-linux}/bin/setsid";
  steam = "/run/current-system/sw/bin/steam";
in
{
  services = {
    sunshine = {
      enable = true;
      autoStart = true;
      capSysAdmin = true; # Only necessary for Wayland apparently
      openFirewall = true;
      applications.apps = [
        {
          name = "Steam Big Picture (iPad)";
          prep-cmd = [
            {
              do = "${kscreen-doctor} output.DP-3.mode.2560x1440@120";
              undo = "${kscreen-doctor} output.DP-3.mode.3440x1440@180";
            }
            {
              do = "";
              undo = "${setsid} ${steam} steam://close/bigpicture";
            }
          ];
          detached = [ "${setsid} ${steam} steam://open/bigpicture" ];
        }
        {
          name = "Steam Big Picture (Apple TV)";
          prep-cmd = [
            {
              do = "${kscreen-doctor} output.DP-3.mode.3840x2160@59.94";
              undo = "${kscreen-doctor} output.DP-3.mode.3440x1440@180";
            }
            {
              do = "";
              undo = "${setsid} ${steam} steam://close/bigpicture";
            }
          ];
          detached = [ "${setsid} ${steam} steam://open/bigpicture" ];
        }
      ];
    };
  };
}
