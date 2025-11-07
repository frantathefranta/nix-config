{ lib, ... }:
{
  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [ "systemd" ];
    openFirewall = lib.mkDefault true;
  };
}
