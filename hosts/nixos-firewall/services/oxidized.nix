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
  systemd.tmpfiles.rules = [ "d ${directory} 0750 ${user} ${group}" ];
  services.oxidized = {
    enable = true;
    routerDB = config.sops.secrets."oxidized/routerdb".path;
    configFile = pkgs.writeText "oxidized-config.yml" ''
      ---
      debug: true
      use_syslog: true
      input:
        default: ssh
        ssh:
          secure: true
      interval: 3600
      # model_map:
      #   dell: powerconnect
      #   hp: procurve
      source:
        default: csv
        csv:
          delimiter: !ruby/regexp /:/
          # file: "/var/lib/oxidized/.config/oxidized/router.db"
          map:
            name: 0
            model: 1
            username: 2
            password: 3
      pid: "${directory}/.config/oxidized/pid"
      # rest: 127.0.0.1:8888
      retries: 3
      # ... additional config
    '';

  };

  sops.secrets."oxidized/routerdb" = {
    sopsFile = ../secrets.yaml;
    owner = user;
    group = group;
  };
}
