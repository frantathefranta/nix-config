{ config, ... }:

{
  services.bird-lg = {
    proxy = {
      enable = true;
      listenAddresses = "0.0.0.0:8000";
      allowedIPs = [
        "${config.meta.dn42.ipv6Prefix48}::/48"
      ];
      birdSocket = "/var/run/bird/bird.ctl";
    };
  };
}
