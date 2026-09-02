{ config, ... }:
{
  services.plex = {
    enable = true;
    openFirewall = true;
  };
  networking.domains.subDomains = {
    "plex.${config.networking.domain}".cname.data = config.networking.hostName;
  };
}
