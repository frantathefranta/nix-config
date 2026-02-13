{
  config,
  lib,
  pkgs,
  ...
}:

let
  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in
{
  users.users.admin = {
    description = "Admin";
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = ifTheyExist [
      "wheel"
    ];

    openssh.authorizedKeys.keys = lib.splitString "\n" (
      builtins.readFile ../../../../home/fbartik/ssh.pub
    );
    packages = [ pkgs.home-manager ];
  };

  home-manager.users.admin = import ../../../../home/admin/${config.networking.hostName}.nix;
}
