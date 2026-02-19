{
  config,
  outputs,
  lib,
  pkgs,
  ...
}:
let
  nixosConfigs = builtins.attrNames outputs.nixosConfigurations;
  homeConfigs = map (n: lib.last (lib.splitString "@" n)) (
    builtins.attrNames outputs.homeConfigurations
  );
  hostnames = lib.unique (homeConfigs ++ nixosConfigs);
  isWorkstation = pkgs.stdenv.isDarwin || (builtins.length config.monitors != 0);
  identityAgent =
    if pkgs.stdenv.isDarwin then
      "'${config.home.homeDirectory}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock'"
    else if (builtins.length config.monitors != 0) then
      "${config.home.homeDirectory}/.1Password/agent.sock"
    else
      "${config.home.homeDirectory}/.ssh/ssh_auth_sock";
in
{
  programs.ssh = {
    includes = [
      "${config.home.homeDirectory}/.ssh/ephemeral_config"
    ];
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "github.com" = {
        inherit identityAgent;
      };
      "brocade*" = lib.mkIf (!pkgs.stdenv.isDarwin) {
        user = "admin";
        inherit identityAgent;
        extraOptions = {
          KexAlgorithms = "+diffie-hellman-group1-sha1";
          HostKeyAlgorithms = "+ssh-rsa";
          PubkeyAcceptedAlgorithms = "+ssh-rsa";
        };
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
        inherit identityAgent;
      };
    };
  };
  home.file.".config/1Password/ssh/agent.toml" = lib.mkIf isWorkstation {
    source = (pkgs.formats.toml { }).generate "agent.toml" {
      "ssh-keys" = [
        {
          vault = "SSH";
          item = "rcrhyzps3y7tpmg5ghz7xpwyj4"; 
        }
        # {
        #   vault = "SSH";
        #   item = "4asutv4ihemt5phe3eakbxcqxe"; # git key
        # }
        {
          vault = "SSH";
          item = "5yo45wnti4mcbz3eahp3dcfn5i"; # Brocade
        }
        {
          vault = "SSH";
          item = "Hetzner Key";
        }
        {
          vault = "SSH";
          item = "Google Key";
        }
      ];
    };
  };
  home.file.".ssh/rc" = lib.mkIf (!isWorkstation && config.programs.tmux.enable) {
    executable = true;
    text = /* bash */ ''
      #!/usr/bin/env bash

      # Fix SSH auth socket location so agent forwarding works with tmux.
      if test "$SSH_AUTH_SOCK" ; then
        ln -sf $SSH_AUTH_SOCK ${config.home.homeDirectory}/.ssh/ssh_auth_sock
      fi
    '';
  };
}
