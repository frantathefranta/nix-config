{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.conman;
  conmanPkg = cfg.package;

  configFile = pkgs.writeText "conman.conf" ''
    ${optionalString (cfg.enableCoreDump) "server coredump=yes"}
    ${optionalString (
      cfg.enableCoreDump && cfg.coreDumpDir
    ) "server coredumpdir=${toString cfg.coreDumpDir}"}
    ${optionalString (cfg.disableKeepalive) "server keepalive=off"}
    ${optionalString (cfg.disableOnlyLoopback) "server loopback=on"}
    ${optionalString (cfg.listeningPort) "server port ${toString cfg.listeningPort}"}

    ${optionalString (cfg.globalSerOpts) "global seropts=${toString cfg.globalSerOpts}"}
    ${optionalString (cfg.globalLogDir) "global log=${cfg.globalLogDir}"}

    ${cfg.extraConfig}
  '';
  conmandFlags = [
    "-F"
    "-c"
    "${configFile}"
  ];
in
{
  options = {
    services.conman = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable the conman Console manager
        '';
      };
      package = mkPackageOption pkgs "conman" { };

      enableCoreDump = mkOption {
        type = types.bool;
        default = false;
        description = ''
          The daemon's COREDUMP keyword specifies whether the daemon should generate a
            core dump file.  This file will be created in the current working directory
            (or '/' when running in the background) unless you also set COREDUMPDIR.
            The default is OFF.
        '';
      };
      coreDumpDir = mkOption {
        type = types.strings;
        default = "";
        description = ''
          The daemon's COREDUMP keyword specifies whether the daemon should generate a
            core dump file.  This file will be created in the current working directory
            (or '/' when running in the background) unless you also set COREDUMPDIR.
            The default is OFF.
        '';
      };
      disableKeepAlive = mkOption {
        type = types.bool;
        default = false;
        description = ''
          The daemon's KEEPALIVE keyword specifies whether the daemon will use
            TCP keep-alives for detecting dead connections.  The default is ON.
        '';
      };

      disableOnlyLoopback = mkOption {
        type = types.bool;
        default = false;
        description = ''
          # TODO: Add description
        '';
      };

      listeningPort = mkOption {
        type = types.ints.positive;
        default = 7890;
        description = ''
          # TODO: Add description
        '';
      };

      globalSerOpts = mkOption {
        type = types.string;
        default = "";
        description = ''
          # TODO: Add description
        '';
      };

      globalLogDir = mkOption {
        type = types.string;
        default = "";
        description = ''
          # TODO: Add description
        '';
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Extra configuration directives that should be added to
          `conman.conf`
        '';
      };
    };
  };
  meta.maintainers = with lib.maintainers; [
    frantathefranta
  ];

  config = mkIf cfg.enable {
    environment.systemPackages = [ conmanPkg ];
    systemd.services.conmand = {
      description = "serial console management program";
      documentation = "man:conman(8)";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${conmanPkg}/bin/conmand ${builtins.toString conmandFlags}";
        KillMode = "process";
      };

    };
  };

}
