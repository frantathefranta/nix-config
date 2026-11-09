{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.packages = [ pkgs.nono ];

  programs.pi-coding-agent.settings.packages = lib.mkAfter [
    { source = "${config.xdg.configHome}/nono/packages/nolabs-ai/pi"; }
  ];
}
