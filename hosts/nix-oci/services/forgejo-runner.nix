{ pkgs, config, ... }:
{
  services.forgejo.runner = {
    # enable = true;
    instances.${config.networking.hostName} = {
      enable = true;
      # Direct from https://code.forgejo.org/forgejo/runner/src/branch/main/internal/pkg/config/config.example.yaml
      settings = {
        # container.enable_ipv6 = true;
        container.network = "podman";
        cache = {
          proxy_port = 4000;
          actions_cache_url_override = "http://host.containers.internal:4000";
        };
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
      autoPrune.enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };
  # Allow containers to reach the runner's cache proxy via host.containers.internal
  networking.firewall.interfaces."podman0".allowedTCPPorts = [ 4000 ];

  sops.secrets.forgejo-runner-token = {
    sopsFile = ../secrets.yaml;
    mode = "0444";
  };
}
