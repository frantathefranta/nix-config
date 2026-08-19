{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [ ./packages ];
  programs.pi-coding-agent = {
    enable = true;
    settings = {
      compaction = {
        enabled = true;
        keepRecentTokens = 20000;
        reserveTokens = 16384;
      };
      enableInstallTelemetry = false;
      extensions = [ ./extensions ];
      skills = [ ./skills ];
    };
  };
  home.sessionVariables = {
    PI_SKIP_VERSION_CHECK = true;
    PI_TELEMETRY = false;
  };
}
