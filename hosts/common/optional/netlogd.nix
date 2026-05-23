{
  config,
  lib,
  pkgs,
  ...
}:

let
  netlogd = pkgs.systemd-netlogd.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      sed -i "s|conf.set_quoted('PKGSYSCONFDIR'.*get_option('sysconfdir')|conf.set_quoted('PKGSYSCONFDIR', '/etc/systemd'|" meson.build
    '';
  });
in
{
  users.users."systemd-journal-netlog" = {
    group = config.users.groups."systemd-journal".name;
    isSystemUser = true;
  };
  environment.etc."systemd/netlogd.conf".text = ''
    [Network]
    Address=10.0.10.1:514

  '';
  systemd.services.systemd-netlogd = {
    description = "Journal Syslog Unicast and Multicast Daemon";
    documentation = [ "man:systemd-netlogd(8)" ];
    after = [ "network.target" ];
    restartTriggers = [ config.environment.etc."systemd/netlogd.conf".source ];
    serviceConfig = {
      ExecStart = "${netlogd}/bin/systemd-netlogd";
      WatchdogSec = "20min";
      Environment = "SYSTEMD_LOG_LEVEL=debug";
      # LockPersonality = true;
      # MemoryDenyWriteExecute = true;
      # PrivateTmp = true;
      # PrivateDevices = true;
      # ProtectClock = true;
      # ProtectControlGroups = true;
      # ProtectHome = true;
      # ProtectHostname = true;
      # ProtectKernelLogs = true;
      # ProtectKernelModules = true;
      # ProtectKernelTunables = true;
      # ProtectProc = "invisible";
      # ProtectSystem = "strict";
      StateDirectory = "systemd/journal-netlogd";
      # SystemCallArchitectures = "native";
    };
    wantedBy = [ "multi-user.target" ];
  };
}
