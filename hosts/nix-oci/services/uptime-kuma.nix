{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.uptime-kuma = {
    enable = true;
    package = pkgs.unstable.uptime-kuma;
  };
  services.caddy = {
    enable = true;
    virtualHosts."uptime.franta.us" = {
      extraConfig = ''
        reverse_proxy :3001
      '';
    };
  };
  networking.firewall.interfaces.enp0s6.allowedTCPPorts = [
    80
    443
  ];
}
