{ pkgs, inputs, ... }:
let
  kscreen-doctor = "${pkgs.kdePackages.libkscreen}/bin/kscreen-doctor";
  # Wayland needs sudo -u $USER (https://wiki.nixos.org/wiki/Sunshine#Running_Steam_Big_Picture_on_Wayland)
  setsid = "sudo -u fbartik ${pkgs.util-linux}/bin/setsid";
  steam = "/run/current-system/sw/bin/steam";
in
{
  imports = [ inputs.moonshine.nixosModules.default ];

  services = {
    moonshine = {
      enable = true;

      # The user whose applications you want to stream.
      user = "fbartik";
      # Only needed when the user's uid is not declared in your
      # configuration. Check with `id -u alice`.
      uid = 1000;

      # Opens the GameStream ports. Only do this on a LAN or VPN-facing
      # firewall. See Security in the main README.
      openFirewall = true;

      # Everything from the Configuration section of the main README goes
      # here, written as nix instead of TOML.
      settings = {
        application_scanner = [
          {
            type = "steam";
            library = "$HOME/.local/share/Steam";
            command = [
              steam
              "-bigpicture"
              "steam://rungameid/{game_id}"
            ];
          }
        ];
        application = [
          {
            title = "Steam";
            command = [
              steam
              "steam://open/bigpicture"
            ];
          }
        ];
      };
    };
  };
}
