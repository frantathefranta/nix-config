{ pkgs, ... }:
{
  programs.firefox = {
    enable = true;
    nativeMessagingHosts = with pkgs.kdePackages; [
      plasma-browser-integration
    ];
  };
}
