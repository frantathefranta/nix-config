{
  config,
  outputs,
  lib,
  ...

}:
let
  nixosConfigs = builtins.attrNames outputs.nixosConfigurations;
  homeConfigs = map (n: lib.last (lib.splitString "@" n)) (
    builtins.attrNames outputs.homeConfigurations
  );
  hostnames = lib.unique (homeConfigs ++ nixosConfigs);
in
{
  programs.ssh = {
    includes = [
      "${config.home.homeDirectory}/.ssh/ephemeral_config"
    ];
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "brocade*" = {
        user = "admin";
        identityFile = config.sops.secrets."ssh/brocade_2048".path;
        extraOptions = {
          KexAlgorithms = "+diffie-hellman-group1-sha1";
          HostKeyAlgorithms = "+ssh-rsa";
          PubkeyAcceptedAlgorithms = "+ssh-rsa";
        };
      };
      "github.com" = {
        identityFile = config.sops.secrets."ssh/git_key".path;
      };
      "hetzner.vm.franta.us" = {
        user = "root";
      };
      net = {
        forwardAgent = true;
        host = lib.concatStringsSep " " (
          lib.flatten (
            map (host: [
              host
              "${host}.franta.us"
              "${host}.infra.franta.us"

            ]) hostnames
          )
        );
        identityAgent = lib.mkIf (builtins.length config.monitors != 0) "~/.1password/agent.sock";
      };
    };
  };
  home.file.".ssh/rc" = lib.mkIf (config.programs.tmux.enable) {
    executable = true;
    text = ''
      #!/usr/bin/env bash

      # Fix SSH auth socket location so agent forwarding works with tmux.
      if test "$SSH_AUTH_SOCK" ; then
        ln -sf $SSH_AUTH_SOCK ${config.home.homeDirectory}/.ssh/ssh_auth_sock
      fi
    '';
  };
  sops.secrets = {
    "ssh/brocade_2048" = {
      sopsFile = ../../secrets.yml;
    };
    "ssh/git_key" = {
      sopsFile = ../../secrets.yml;
    };
  };
}
