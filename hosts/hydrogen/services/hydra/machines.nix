{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  # gRPC has no bearer token: restrict both endpoints with Unix-socket
  # permissions, and authenticate the ARM link with the existing SSH key.
  services.hydra.queueRunner = {
    grpc.unixSocket = "/run/hydra-queue-runner-grpc.sock";
    settings.maxUnsupportedTimeInS = 30;
  };
  systemd.sockets.hydra-queue-runner-grpc.socketConfig = {
    SocketGroup = "hydra";
    SocketMode = "0660";
  };

  services.hydra-builder = {
    enable = true;
    queueRunnerAddr = "unix:///run/hydra-queue-runner-grpc.sock";
    settings = {
      systems = [ "x86_64-linux" "aarch64-linux" "i686-linux" ];
      maxJobs = 1;
      supportedFeatures = [ "kvm" "big-parallel" "nixos-test" ];
    };
  };

  programs.ssh.knownHosts.hydra-arm-builder = {
    hostNames = [ "nix-oci.cloud.franta.us" ];
    publicKeyFile = "${inputs.nix-cloud-src}/hosts/nix-oci/ssh_host_ed25519_key.pub";
  };

  systemd.services.hydra-builder-tunnel = {
    description = "Forward the Hydra queue runner to the ARM builder";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" "sops-nix.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = config.users.users.hydra.name;
      Group = config.users.users.hydra.group;
      ExecStart = lib.escapeShellArgs [
        "${pkgs.openssh}/bin/ssh"
        "-NT"
        "-i" config.sops.secrets."hydra/nix-ssh-key".path
        "-o" "BatchMode=yes"
        "-o" "IdentitiesOnly=yes"
        "-o" "StrictHostKeyChecking=yes"
        "-o" "ExitOnForwardFailure=yes"
        "-o" "ServerAliveInterval=30"
        "-o" "ServerAliveCountMax=3"
        "-R" "/run/hydra-tunnel/queue-runner.sock:/run/hydra-queue-runner-grpc.sock"
        "hydra-tunnel@nix-oci.cloud.franta.us"
      ];
      Restart = "always";
      RestartSec = "5s";
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
    };
  };
}
