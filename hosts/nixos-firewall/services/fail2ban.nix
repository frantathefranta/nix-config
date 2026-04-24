{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.fail2ban = {
    enable = true;
    ignoreIP = [
      "192.148.249.2"
    ];
  };
}
