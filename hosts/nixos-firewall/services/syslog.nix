{ pkgs, ... }:
{
  services.rsyslogd = {
    enable = true;
    # Rainerscript doesn't work with current NixOS config because supplied nixos.conf still has some old syntax settings
    # extraConfig = ''
    #   module(load="imudp")
    #   input(type="imudp" port="514")
    #   template(name="RSYSLOG_FileFormat)
    # '';
    extraConfig = ''
      $ModLoad imudp
      $UDPServerRun 514

      $template RemoteStore, "/var/spool/rsyslog/%HOSTNAME%/%timegenerated:1:10:date-rfc3339%"
      :source, !isequal, "localhost" -?RemoteStore
      :source, isequal, "last" stop
    '';
  };
  systemd = {
    services.rsyslog-cleanup = {
      after = [ "multi-user.target" ];
      description = "Delete log files older than 30 days";
      script = "${pkgs.findutils}/bin/find /var/spool/rsyslog/ -daystart -mtime +30 -type f -exec rm -f {} \\;";
      startAt = "weekly";
      serviceConfig.Type = "oneshot";
    };
    timers.rsyslog-cleanup = {
      timerConfig = {
        Persistent = true;
      };
    };
  };
  networking.nftables.firewall.rules.allow_syslog = {
    from = [
      "lab_space"
      "local_interfaces"
    ];
    to = [ "fw" ];
    allowedUDPPorts = [ 514 ];
  };
}
