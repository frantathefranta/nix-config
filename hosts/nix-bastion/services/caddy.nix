{
  config,
  pkgs,
  ...
}:

{
  services.caddy = {
    enable = true;
    environmentFile = config.sops.secrets."caddy/cloudflare".path;
    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/caddy-dns/cloudflare@v0.2.4" ];
      hash = "sha256-8HpPZ/VoiV/k0ZYcnXHmkwuEYKNpURKTN19aYZRLPoM=";
    };
    globalConfig = ''
      acme_dns cloudflare {$CLOUDFLARE_TOKEN}
    '';
    virtualHosts."ssh.franta.dev" = {
      extraConfig = ''
        reverse_proxy http://localhost:8082
      '';
    };
  };
  networking.firewall.interfaces.ens18.allowedTCPPorts = [
    443
  ];
  sops.secrets."caddy/cloudflare" = {
    sopsFile = ../secrets.yaml;
    owner = "caddy";
    group = "caddy";
  };
}
