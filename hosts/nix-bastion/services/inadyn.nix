{ config, ... }:

{
  services = {
    inadyn = {
      enable = true;
      logLevel = "debug";
      settings = {
        provider = {
          "cloudflare.com" = {
            include = config.sops.secrets."inadyn-secret/cloudflare".path;
          };
        };
      };
    };
  };
  sops.secrets = {
    "inadyn-secret/cloudflare" = {
      sopsFile = ../secrets.yaml;
      owner = "inadyn";
      group = "inadyn";
    };
  };
}
