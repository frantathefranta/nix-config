{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:
let
  kscreen-doctor = "${pkgs.kdePackages.libkscreen}/bin/kscreen-doctor";
  # Wayland needs sudo -u $USER (https://wiki.nixos.org/wiki/Sunshine#Running_Steam_Big_Picture_on_Wayland)
  setsid = "sudo -u fbartik ${pkgs.util-linux}/bin/setsid";
  steam = "/run/current-system/sw/bin/steam";

  moonshine-boxart = pkgs.runCommand "moonshine-boxart" { } ''
    mkdir -p $out
    cp ${pkgs.steam-unwrapped}/share/icons/hicolor/256x256/apps/steam.png $out/steam.png
  '';

  # Steam is single-instance per user: if it's already running on the desktop
  # session, "steam steam://open/bigpicture" just focuses that instance
  # instead of giving Moonshine's streaming session its own Big Picture.
  stopDesktopSteam = ''
    if pgrep -x steam >/dev/null; then
      steam -shutdown >/dev/null 2>&1 || true
      for _ in $(seq 1 30); do
        pgrep -x steam >/dev/null || break
        sleep 1
      done
    fi
  '';

  # Moonshine's Vulkan capture layer manifest needs to be discoverable to
  # Steam, Proton, and their Vulkan loaders.
  moonshineDataDirs = ''export XDG_DATA_DIRS="${config.services.moonshine.package}/share:''${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"'';

  moonshine-steam = pkgs.writeShellApplication {
    name = "moonshine-steam";
    runtimeInputs = [
      pkgs.procps
      config.programs.steam.package
    ];
    text = ''
      ${stopDesktopSteam}
      ${moonshineDataDirs}
      exec steam steam://open/bigpicture
    '';
  };

  # Workaround for hgaiser/moonshine#93: DX11 games (GTA V included) go black
  # over Moonshine while audio/input keep working. Wrapping Steam in Gamescope
  # makes Gamescope own the swapchain Moonshine's compositor sees, so games
  # present to Gamescope instead of creating their own DX11 WSI swapchain.
  gamescopeHdr = pkgs.gamescope.override { enableWsi = true; };

  moonshine-steam-gamescope = pkgs.writeShellApplication {
    name = "moonshine-steam-gamescope";
    runtimeInputs = [
      gamescopeHdr
      pkgs.procps
      config.programs.steam.package
    ];
    text = ''
      ${stopDesktopSteam}
      export XDG_DATA_DIRS="${config.services.moonshine.package}/share:${gamescopeHdr}/share:''${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"

      # Games inside Gamescope present to Gamescope's own compositor, and
      # Gamescope presents to Moonshine as a plain client, so Moonshine's WSI
      # layer would only get in the way here.
      export DISABLE_MOONSHINE_WSI=1
      unset ENABLE_MOONSHINE_WSI

      w=''${MOONSHINE_CLIENT_WIDTH:-1920}
      h=''${MOONSHINE_CLIENT_HEIGHT:-1080}
      rate=''${MOONSHINE_CLIENT_FRAMERATE:-60}

      exec ${gamescopeHdr}/bin/gamescope --steam -f -b -W "$w" -H "$h" -w "$w" -h "$h" -r "$rate" --hdr-enabled -- steam -tenfoot
    '';
  };
in
{
  imports = [ inputs.moonshine.nixosModules.default ];

  users.groups.moonshine.members = [ "fbartik" ];
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
          {
            type = "lutris";
            command = [
              "${pkgs.lutris}/bin/lutris"
              "lutris:rungame/{slug}"
            ];
          }
        ];
        application = [
          {
            title = "Steam Big Picture";
            boxart = "${moonshine-boxart}/steam.png";
            command = [ "${moonshine-steam}/bin/moonshine-steam" ];
          }
          {
            title = "Steam Big Picture (Gamescope)";
            boxart = "${moonshine-boxart}/steam.png";
            command = [ "${moonshine-steam-gamescope}/bin/moonshine-steam-gamescope" ];
          }
        ];
      };
    };
  };
}
