{ config, ... }:

{
  services = {
    inadyn = {
      enable = true;
      settings = {
        provider = {
          "cloudflare.com:1" = {
            include = config.sops.secrets."inadyn-secret/cloudflare-ipv4".path;
          };
          "cloudflare.com:2" = {
            include = config.sops.secrets."inadyn-secret/cloudflare-ipv6".path;
          };
        };
      };
    };
  };
  sops.secrets."inadyn-secret/cloudflare-ipv4" = {
    sopsFile = ../secrets.yaml;
    owner = "inadyn";
    group = "inadyn";
  };
  sops.secrets."inadyn-secret/cloudflare-ipv6" = {
    sopsFile = ../secrets.yaml;
    owner = "inadyn";
    group = "inadyn";
  };
}
