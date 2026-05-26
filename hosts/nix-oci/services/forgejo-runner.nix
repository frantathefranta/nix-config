{ pkgs, config, ... }:
{
  services.forgejo.runner = {
    # enable = true;
    instances.${config.networking.hostName} = {
      enable = true;
      settings = {
        server.connections.codeberg = {
          labels = [
            "native:host"
            "ubuntu:docker://ghcr.io/catthehacker/ubuntu:act-latest"
          ];
          token_url = "file:${config.sops.secrets.forgejo-runner-token.path}";
          url = "https://codeberg.org";
          uuid = "ba743698-fb38-4185-b89c-045cfce93ba0";
        };

      };
    };
  };
  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
    };
  };
  sops.secrets.forgejo-runner-token = {
    sopsFile = ../secrets.yaml;
    mode = "0444";
  };
}
