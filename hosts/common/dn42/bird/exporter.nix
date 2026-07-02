{ config, ... }:

{
  services.prometheus.exporters.bird = {
    enable = true;
    openFirewall = false;
  };
  networking.nftables.firewall.rules.allow_bird_exporter = {
    from = [
      "my_dn42_prefix"
      "my_home_prefix"
    ];
    to = [ "fw" ];
    allowedTCPPorts = [ config.services.prometheus.exporters.bird.port ];
  };
}
