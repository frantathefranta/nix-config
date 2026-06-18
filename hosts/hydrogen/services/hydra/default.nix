{
  pkgs,
  config,
  outputs,
  ...
}:
let
  hydraUser = config.users.users.hydra.name;
  hydraGroup = config.users.users.hydra.group;
in
{
  imports = [ ./machines.nix ];

  # https://github.com/NixOS/nix/issues/4178#issuecomment-738886808
  systemd.services.hydra-evaluator.environment.GC_DONT_GC = "true";

  services = {
    hydra = {
      enable = true;
      package = pkgs.hydra;
      hydraURL = "https://hydra.infra.franta.us";
      notificationSender = "hydra@franta.us";
      listenHost = "localhost";
      smtpHost = "localhost";
      useSubstitutes = true;
      extraConfig = /* xml */ ''
        max_unsupported_time = 30
        allow_import_from_derivation = true
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
  networking.domains.subDomains."hydra.${config.networking.domain}".cname.data = "${config.networking.hostName}";
  users.users = {
    hydra-queue-runner.extraGroups = [ hydraGroup ];
    hydra-www.extraGroups = [ hydraGroup ];
  };
  sops.secrets = {
    # Might need a Gitea/Forgejo equivalent
    # hydra-gh-auth = {
    #   sopsFile = ../../secrets.yaml;
    #   owner = hydraUser;
    #   group = hydraGroup;
    #   mode = "0440";
    # };
    # Only needed if I add remote-builders
    # nix-ssh-key = {
    #   sopsFile = ../../secrets.yaml;
    #   owner = hydraUser;
    #   group = hydraGroup;
    #   mode = "0440";
    # };
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
