{ config, ... }:

{
  # If IPv6 temp addresses are enabled, the wrong IP gets added as AAAA record
  networking.tempAddresses = "disabled";
  services = {
    inadyn = {
      enable = true;
      settings = {
        provider = {
          # Cloudflare needs IPv4 and IPv6 be done separately: https://github.com/troglobit/inadyn/blob/master/examples/cloudflare-ipv4-ipv6.conf
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
