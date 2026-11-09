{
  inputs,
  pkgs,
  config,
  ...
}:
{
  imports = [
    inputs.hardware.nixosModules.common-cpu-intel
    inputs.hardware.nixosModules.common-pc-ssd
    ./services
    ./hardware-configuration.nix

    ../common/global
    ../common/users/fbartik
    ../common/optional/comin.nix
    ../common/optional/prometheus-node-exporter.nix
  ];
  # Disable immediate post-deployment reboots; use the maintenance timer below.
  services.comin.autoReboot = false;

  systemd.timers.comin-scheduled-reboot = {
    description = "Check for pending reboots during the Sunday maintenance window";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      # Every 15 minutes on Sunday, from 02:00 through 04:45, local time.
      OnCalendar = "Sun *-*-* 02..04:00/15:00";
      Persistent = false;
      AccuracySec = "1min";
      RandomizedDelaySec = 0;
    };
  };

  systemd.services.comin-scheduled-reboot = {
    description = "Reboot if Comin reports a pending reboot";
    serviceConfig.Type = "oneshot";
    script = ''
      set -euo pipefail

      if ${config.services.comin.package}/bin/comin status \
        | ${pkgs.ripgrep}/bin/rg -q 'Need to reboot: yes'; then
        # Enforce the window even for delayed or manually started runs.
        # date uses the host's local timezone (America/Detroit, including DST).
        # +%u gives the weekday: Monday=1 through Sunday=7.
        # +%-H gives the 24-hour clock hour without a leading zero, avoiding
        # Bash interpreting zero-prefixed numbers as octal in arithmetic.
        weekday=$(${pkgs.coreutils}/bin/date +%u)
        hour=$(${pkgs.coreutils}/bin/date +%-H)

        # Sunday only, with 02:00 inclusive and 05:00 exclusive.
        if (( weekday == 7 && hour >= 2 && hour < 5 )); then
          ${pkgs.systemd}/bin/systemctl reboot
        fi
      fi
    '';
  };

  networking = {
    hostName = "nixos-firewall";
    domain = "infra.franta.us";
    domains.subDomains = {
      "${config.networking.hostName}-lan0.${config.networking.domain}" = {
        a.data = [ "10.0.10.1" ];
        aaaa.data = [ "2600:1702:6630:3fe0:10:0:10:1" ];
      };
      "${config.networking.hostName}-mgmt.${config.networking.domain}" = {
        a.data = [ "10.32.10.230" ];
        aaaa.data = [ "2600:1702:6630:3fed:10:32:10:230" ];
      };
      "${config.networking.hostName}.${config.networking.domain}".cname.data =
        "${config.networking.hostName}-lan0";
      "time.${config.networking.domain}".cname.data = "${config.networking.hostName}";
      "logs.${config.networking.domain}".cname.data = "${config.networking.hostName}";
      "nut.${config.networking.domain}".cname.data = "${config.networking.hostName}";
    };
  };
  meta.ipam.host = {
    ipv4 = "10.0.10.1";
    ipv6 = "2600:1702:6630:3fe0:10:0:10:1";
  };
  time.timeZone = "America/Detroit";
  environment.systemPackages = [
    pkgs.i2c-tools
    pkgs.vep14xx-diags
  ];

  documentation.man.man-db.enable = false;
  system.stateVersion = "25.11";
}
