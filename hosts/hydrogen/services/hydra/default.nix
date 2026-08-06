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
  #
  # NOTE: as of pkgs.hydra 0-unstable-2026-03-13, the Perl plugin tree still
  # lives at src/lib/Hydra/Plugin/. Hydra's repo moved this under
  # subprojects/hydra/lib/Hydra/Plugin/ a few days later upstream -- if a
  # nixpkgs bump ever pulls that layout in, this path will need updating
  # (check `pkgs.hydra.src` for a `subprojects/` dir).
  hydraPackage = pkgs.hydra.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      cp ${./plugins/GiteaPulls.pm} src/lib/Hydra/Plugin/GiteaPulls.pm
    '';
  });
in
{
  imports = [ ./machines.nix ];

  # https://github.com/NixOS/nix/issues/4178#issuecomment-738886808
  systemd.services.hydra-evaluator.environment.GC_DONT_GC = "true";

  services = {
    hydra = {
      enable = true;
      package = hydraPackage;
      hydraURL = "https://hydra.infra.franta.us";
      notificationSender = "hydra@franta.us";
      listenHost = "localhost";
      smtpHost = "localhost";
      useSubstitutes = true;
      extraConfig = /* xml */ ''
        max_unsupported_time = 30
        max_concurrent_evals = 2
        allow_import_from_derivation = true
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
            reverse_proxy localhost:${toString config.services.hydra.port}
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
    # Only needed if I add remote-builders
    "hydra/nix-ssh-key" = {
      sopsFile = ../../secrets.yaml;
      owner = hydraUser;
      group = hydraGroup;
      mode = "0600";
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
