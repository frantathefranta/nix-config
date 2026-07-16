{
  config,
  pkgs,
  ...
}:
{
  sops.secrets.cache-sig-key = {
    sopsFile = ../secrets.yaml;
  };

  services = {
    nix-serve = {
      enable = true;
      /*
        $ nix key generate-secret --key-name nix-cache.infra.franta.us > nix-cache-priv-key
        $ nix key convert-secret-to-public < nix-cache-priv-key > nix-cache-pub-key
      */
      secretKeyFile = config.sops.secrets.cache-sig-key.path;
      package = pkgs.nix-serve-ng; # Arista's /improved/ nix-serve
    };
    caddy.virtualHosts."nix-cache.infra.franta.us" = {
      extraConfig = ''
        reverse_proxy localhost:${toString config.services.nix-serve.port}
      '';
    };
    # nginx.virtualHosts."cache.m7.rs" = {
    #   forceSSL = true;
    #   enableACME = true;
    #   locations."/".extraConfig = ''
    #     proxy_pass http://localhost:${toString config.services.nix-serve.port};
    #     proxy_set_header Host $host;
    #     proxy_set_header X-Real-IP $remote_addr;
    #     proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    #   '';
    # };
  };
  networking.domains.subDomains."nix-cache.${config.networking.domain}".cname.data =
    "${config.networking.hostName}";
}
