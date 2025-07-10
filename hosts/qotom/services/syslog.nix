{
  services.rsyslogd = {
    enable = true;
    extraConfig = ''
      $ModLoad imudp
      $UDPServerRun 514
      $AllowedSender UDP, 10.32.0.0/15 127.0.0.1

      $template RemoteStore, "/var/log/remote/%HOSTNAME%/%timegenerated:1:10:date-rfc3339%"
      :source, !isequal, "localhost" -?RemoteStore
      :source, isequal, "last" stop
    '';
  };
}
