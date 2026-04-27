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
      "10.32.10.0/24"
      "2600:1702:6630:3fed::/64"
    ];
  };
}
