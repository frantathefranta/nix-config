{ lib, ... }:
{
  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [ "systemd" ];
    openFirewall = lib.mkDefault true;
    listenAddress = lib.mkDefault "127.0.0.1";
  };
}
