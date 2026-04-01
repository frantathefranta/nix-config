{
  config,
  ...
}:

{
  services.caddy = {
    enable = true;
    environmentFile = config.sops.secrets."caddy/cloudflare".path;
    globalConfig = ''
      acme_dns cloudflare $CLOUDFLARE_TOKEN
    '';
    virtualHosts."ssh.franta.dev" = {
      extraConfig = ''
        reverse_proxy http://localhost:8082
      '';
    };
  };
  networking.firewall.interfaces.enp1s0.allowedTCPPorts = [
    443
  ];
  sops.secrets."caddy/cloudflare" = {
    sopsFile = ../secrets.yaml;
    owner = "caddy";
    group = "caddy";
  };
}
