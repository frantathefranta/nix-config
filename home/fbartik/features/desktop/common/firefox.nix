{ pkgs, config, ... }:
{
  programs.firefox = {
    enable = true;
    nativeMessagingHosts = with pkgs.kdePackages; [
      plasma-browser-integration
    ];
    configPath = "${config.xdg.configHome}/mozilla/firefox";
  };
}
