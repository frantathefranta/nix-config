{
  config,
  lib,
  pkgs,
  ...
}:

let
  oxi-cfg = config.services.oxidized;
  directory = oxi-cfg.dataDir;
  user = oxi-cfg.user;
  group = oxi-cfg.group;
in
{
  systemd = {
    # 10-oxidized is the upstream tmpfile that creates the oxidized directory, among other things
    tmpfiles.settings."10-oxidized" = {
      "${directory}/.ssh" = {
        "d" = {
          mode = "0750";
          user = user;
          group = group;
        };
      };
      "${directory}/.ssh/known_hosts" = {
        "f" = {
          mode = "0600";
          user = user;
          group = group;
          argument = "git.franta.us ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDI4xjbgmyi2pUOyR5PcEg6v5yqHKrAPfmz98vyAAB4LfIEcxkmQNwce+b/JCdKHPfXdmN5oe9UlzPfxNccdvrl6krzuFu7drl+qhZwNf98hZ+W6I/sdjCBoRmuPJj/Wipp/jx7v0AUZ7xjfeQEVvdTJFgxK1khdytGLDNuDfihjQl4F+TGy7h3NN2AIJLlVPMccOhRqCN6yiIBK4aMNCjqYsC8Jo3Gse0sHDOmi+kh0dYA67lGY3FVYrwmzKWonmpQoCoI47T27v6EAO8VCIbAmZY+1NSzkXdwE16SMsVSuMN+sXuSczycrqZv4MYTxlPHBFQUxwKm+ee+T7muUVeFz2Ouyt1iBeIItkPLm2yaQKrUZ4AqsuDFE69puJjFqp8nrDyp+xajVL4Ga2oTybMPoZpd7cmmv3BH9ynEV2v6UQcs84kDIfg24acQhOYfnkp8LuMZz4dt49uvAz6GRjTHecLPyJcXerZNF2fhuROVkdk/6y0u035gunVH1wvjilP6aNJMXHm//SEcXYWxk+OcDcXb3MZlrV4ugahmz0UBybHkePj9xLSkLNUalYVsxQbvIevr6eQi7f3xTB8/WwK0iGmxAZESkAUuufIxx+IPCia1YpW3GYuxFFjXaRpwzAMxDskMqFPorMA4kDWDKUzV41t3Umy9Fw5by+YPbia8ew==";
        };
      };
    };
    services.oxidized.restartTriggers = [ config.services.oxidized.configFile ];
  };
  services.oxidized = {
    enable = true;
    routerDB = pkgs.writeText "oxidized-router.db" ''
      arista.infra.franta.us:eos
      mikrotik.infra.franta.us:routeros
      brocade01-poe.infra.franta.us:fastiron
    '';
    configFile = pkgs.writeText "oxidized-config.yml" ''
      ---
      debug: false
      username: oxidized
      input:
        default: ssh
        ssh:
          secure: false # No ssh key verification
      interval: 3600
      output:
        default: git
        git:
            single_repo: true
            user: oxidized
            email: oxidized@franta.us
            repo: "${directory}/devices.git"
      hooks:
        push_to_remote:
          type: githubrepo
          events: [post_store]
          remote_repo: git@git.franta.us:franta/oxidized.git
          privatekey: ${config.sops.secrets."oxidized/git-private-key".path}
          publickey: ${config.sops.secrets."oxidized/git-public-key".path}
      vars:
        ssh_keys: ${config.sops.secrets."oxidized/switch-ssh-key".path}
        remove_secret: true
        auth_methods:
          - publickey
          - password
          - keyboard-interactive
      source:
        default: csv
        csv:
          delimiter: !ruby/regexp /:/
          file: "${directory}/.config/oxidized/router.db"
          map:
            name: 0
            model: 1
      models:
        fastiron:
          vars:
            ssh_kex: diffie-hellman-group1-sha1
            ssh_host_key: ssh-rsa
            enable: true
        eos:
          vars:
            enable: true
      pid: "${directory}/.config/oxidized/pid"
      retries: 3
    '';

  };

  sops.secrets = {
    "oxidized/switch-ssh-key" = {
      sopsFile = ../secrets.yaml;
      owner = user;
      group = group;
    };
    "oxidized/git-public-key" = {
      sopsFile = ../secrets.yaml;
      owner = user;
      group = group;
    };
    "oxidized/git-private-key" = {
      sopsFile = ../secrets.yaml;
      owner = user;
      group = group;
    };
  };
}
