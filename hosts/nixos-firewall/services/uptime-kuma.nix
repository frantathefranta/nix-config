{ config, pkgs, ... }:
{
  sops.secrets."uptime-kuma/push-url" = {
    sopsFile = ../secrets.yaml;
  };

  systemd.services.uptime-kuma-push = {
    description = "Uptime Kuma push ping";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "uptime-kuma-push" ''
        url=$(cat ${config.sops.secrets."uptime-kuma/push-url".path})
        ${pkgs.curl}/bin/curl -fsS --max-time 10 "$url"
      '';
    };
  };

  systemd.timers.uptime-kuma-push = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "30s";
      OnUnitActiveSec = "30s";
    };
  };
}
