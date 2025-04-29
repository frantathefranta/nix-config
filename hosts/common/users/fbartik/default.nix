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
      "deluge"
      "docker"
      "git"
      "i2c"
      "libvirtd"
      "lxd"
      "minecraft"
      "mysql"
      "network"
      "plugdev"
      "podman"
      "video"
      "wheel"
      "wireshark"
    ];

    openssh.authorizedKeys.keys = lib.splitString "\n" (builtins.readFile ../../../../home/fbartik/ssh.pub);
    # hashedPasswordFile = config.sops.secrets.fbartik-password.path;
    packages = [pkgs.home-manager];
  };

  # sops.secrets.gabriel-password = {
  #   sopsFile = ../../secrets.yaml;
  #   neededForUsers = true;
  # };

  home-manager.users.fbartik = import ../../../../home/fbartik/${config.networking.hostName}.nix;

  security.pam.services = {
    swaylock = {};
  };
}
