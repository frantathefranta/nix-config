{
  pkgs,
  config,
  outputs,
  ...
}:
let
  hydraUser = config.users.users.hydra.name;
  hydraGroup = config.users.users.hydra.group;

  # Backports the (unmerged) GiteaPulls plugin from
  # https://github.com/NixOS/hydra/pull/1431, so declarative jobsets can use
  # a `giteapulls` input to build open Forgejo PRs. Drop this once that PR
  # (or an equivalent) lands upstream.
  hydraPackage = pkgs.hydra.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      cp ${./plugins/GiteaPulls.pm} lib/Hydra/Plugin/GiteaPulls.pm
    '';
  });
in
{
  imports = [
    ./machines.nix
    ./metrics.nix
  ];

  services = {
    hydra = {
      enable = true;
      package = hydraPackage;
      evaluatorSettings.max_concurrent_evals = 2;
      hydraURL = "https://hydra.infra.franta.us";
      notificationSender = "hydra@franta.us";
      listenHost = "localhost";
      smtpHost = "localhost";
      useSubstitutes = true;
      extraConfig = /* xml */ ''
        allow_import_from_derivation = true
        ws_endpoint = wss://hydra.infra.franta.us/ws
        Include ${config.sops.secrets."hydra/gitea-token".path}
      '';
      extraEnv = {
        HYDRA_DISALLOW_UNFREE = "0";
      };
    };
    caddy = {
      virtualHosts = {
        "hydra.infra.franta.us" = {
          extraConfig = ''
            @home-subnets not client_ip 10.32.10.0/24 2600:1702:6630:3fe0::/60
            abort @home-subnets
            handle /ws {
              reverse_proxy [::1]:${toString config.services.hydra.ws.bind.port}
            }
            handle {
              reverse_proxy localhost:${toString config.services.hydra.port}
            }
          '';
        };
      };
    };
  };
  networking.domains.subDomains."hydra.${config.networking.domain}".cname.data =
    "${config.networking.hostName}";
  users.users = {
    hydra-queue-runner.extraGroups = [ hydraGroup ];
    hydra-www.extraGroups = [ hydraGroup ];
  };

  sops.secrets = {
    # Contains a single line `franta = <token>`, Include'd into
    # extraConfig's <gitea_authorization> block above. Used by both the
    # giteapulls and gitea-status Hydra plugins. Add the value yourself
    # with `sops hosts/hydrogen/secrets.yaml`.
    "hydra/gitea-token" = {
      sopsFile = ../../secrets.yaml;
      owner = hydraUser;
      group = hydraGroup;
      mode = "0440";
    };
    # Also authenticates the loopback-only reverse tunnel to the ARM builder.
    "hydra/nix-ssh-key" = {
      sopsFile = ../../secrets.yaml;
      owner = hydraUser;
      group = hydraGroup;
      mode = "0400";
      restartUnits = [ "hydra-builder-tunnel.service" ];
    };
  };

  # environment.persistence = {
  #   "/persist".directories = [
  #     {
  #       directory = config.users.users.hydra.home;
  #       user = config.users.users.hydra.name;
  #       group = config.users.users.hydra.group;
  #       mode = "0700";
  #     }
  #   ];
  # };
}
