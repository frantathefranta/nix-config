{
  services.rsyslogd = {
    enable = true;
    extraConfig = ''
      $ModLoad imudp
      $UDPServerRun 514

      $template RemoteStore, "/var/spool/rsyslog/%HOSTNAME%/%timegenerated:1:10:date-rfc3339%"
      :source, !isequal, "localhost" -?RemoteStore
      :source, isequal, "last" stop
    '';
  };

  networking.nftables.firewall.rules.allow_syslog = {
    from = [ "lab_space" ];
    to = [ "fw" ];
    allowedUDPPorts = [ 514 ];
  };
}
