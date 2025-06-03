{ config, lib, pkgs, ... }:

let
  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in {
  users.mutableUsers = false;
  users.users.fbartik = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = ifTheyExist [
      "audio"
      "dialout"
      "git"
      "i2c"
      "network"
      "plugdev"
      "video"
      "wheel"
    ];

    openssh.authorizedKeys.keys = lib.splitString "\n" (builtins.readFile ../../../../home/fbartik/ssh.pub);
    hashedPasswordFile = config.sops.secrets.fbartik-password.path;
    packages = [pkgs.home-manager];
  };

  sops.secrets.fbartik-password = {
    sopsFile = ../../secrets.yaml;
    neededForUsers = true;
  };
  sops.secrets."ssh/brocade_2048" = {
    sopsFile = ../../secrets.yaml;
    mode = "0600";
    owner = "fbartik";
    group = "users";
    path = "/home/fbartik/.ssh/brocade_2048";
  };

  home-manager.users.fbartik = import ../../../../home/fbartik/${config.networking.hostName}.nix;

  security.pam.services = {
    swaylock = {};
  };
}
