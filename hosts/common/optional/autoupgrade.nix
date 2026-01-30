{ config, lib, ... }:

let
  emailAddress = "admin@franta.us";
  services = [
    "nixos-upgrade"
    "nixos-store-optimize"
  ];
in
{
  system.autoUpgrade = {
    enable = true;
    flake = "github:frantathefranta/nix-config#${config.networking.hostName}";
    flags = [
      "--print-build-logs"
      "--accept-flake-config"
    ];
    dates = "Mon 05:00";
    randomizedDelaySec = "30min";
  };
  # Stolen from https://discourse.nixos.org/t/system-autoupgrade-with-e-mail-notificaitons/32063/4
  # Define systemd template unit for reporting service failures via e-mail
  systemd.services = {
    "notify-email@" = {
      environment.EMAIL_ADDRESS = lib.strings.replaceStrings [ "%" ] [ "%%" ] emailAddress;
      environment.SERVICE_ID = "%i";
      path = [
        "/run/wrappers"
        "/run/current-system/sw"
      ];
      script = ''
        {
           echo "Date: $(date -R)"
           echo "From: root (systemd notify-email)"
           echo "To: $EMAIL_ADDRESS"
           echo "Subject: [$(hostname)] service $SERVICE_ID failed"
           echo "Auto-Submitted: auto-generated"
           echo
           systemctl status "$SERVICE_ID" ||:
        } | sendmail "$EMAIL_ADDRESS"
      '';
    };

    # Merge `onFailure` attribute for all monitored services
  }
  // (lib.attrsets.genAttrs services (name: {
    onFailure = lib.mkBefore [ "notify-email@%i.service" ];
  }));
}
