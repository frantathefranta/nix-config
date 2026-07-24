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
  deployment.targetUser = lib.mkForce "admin";

  users.mutableUsers = false;
  users.users.admin = {
    description = "Admin";
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = ifTheyExist [
      "bird"
      "caddy"
      "git"
      "network"
      "wheel"
    ];

    openssh.authorizedKeys.keys = lib.splitString "\n" (
      builtins.readFile ../../../../home/fbartik/ssh.pub
    );
    hashedPasswordFile = config.sops.secrets.admin-password.path;
    packages = [ pkgs.home-manager ];
  };

  sops.secrets.admin-password = {
    sopsFile = ./secrets.yaml;
    neededForUsers = true;
  };

  home-manager.users.admin = import ../../../../home/admin/${config.networking.hostName}.nix;

  security.pam = {
    # rssh allows approving sudo using the ssh-agent (in my case 1password)
    rssh.enable = true;
    services.sudo.rssh = true;
  };
  security.sudo.wheelNeedsPassword = lib.mkDefault false;
}
