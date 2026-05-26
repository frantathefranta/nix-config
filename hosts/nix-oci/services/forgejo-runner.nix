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
          ];
          token_url = "file:${config.sops.secrets.forgejo-runner-token.path}";
          url = "https://codeberg.org";
          uuid = "ba743698-fb38-4185-b89c-045cfce93ba0";
        };

      };
    };

  };
  # services.gitea-actions-runner = {
  #   package = pkgs.forgejo-runner;
  #   instances.default = {
  #     enable = true;
  #     name = "monolith";
  #     url = "https://codeberg.org";
  #     # Obtaining the path to the runner token file may differ
  #     # tokenFile should be in format TOKEN=<secret>, since it's EnvironmentFile for systemd
  #     tokenFile = config.sops.secrets.forgejo-runner-token.path;
  #     labels = [
  #       # "ubuntu-latest:docker://node:16-bullseye"
  #       # "ubuntu-22.04:docker://node:16-bullseye"
  #       # "ubuntu-20.04:docker://node:16-bullseye"
  #       # "ubuntu-18.04:docker://node:16-buster"
  #       ## optionally provide native execution on the host:
  #       "native:host"
  #     ];
  #   };
  # };
  sops.secrets.forgejo-runner-token = {
    sopsFile = ../secrets.yaml;
    mode = "0755";
  };
}
