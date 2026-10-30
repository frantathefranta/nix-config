{
  services.hydra.extraConfig = ''
    <hydra_notify>
      <prometheus>
        listen_address = 0.0.0.0
        port = 9199
      </prometheus>
    </hydra_notify>
  '';

  services.prometheus.exporters.statsd = {
    enable = true;
    openFirewall = true;
    extraFlags = [
      "--statsd.listen-udp=127.0.0.1:8125"
      "--statsd.listen-tcp="
    ];
  };

  networking.firewall.allowedTCPPorts = [
    9199
  ];
}
