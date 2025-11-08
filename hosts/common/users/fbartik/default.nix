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
  users.mutableUsers = false;
  users.users.fbartik = {
    description = "Franta Bartik";
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = ifTheyExist [
      "audio"
      "dialout"
      "frrvty" # For inspecting vtysh
      "ftdi"
      "git"
      "i2c"
      "network"
      "plugdev"
      "video"
      "wheel"
      "_lldp"
    ];

    openssh.authorizedKeys.keys = lib.splitString "\n" (
      builtins.readFile ../../../../home/fbartik/ssh.pub
    );
    hashedPasswordFile = config.sops.secrets.fbartik-password.path;
    packages = [ pkgs.home-manager ];
  };

  sops.secrets.fbartik-password = {
    sopsFile = ../../secrets.yaml;
    neededForUsers = true;
  };
  sops.secrets.kubeconfig = {
    sopsFile = ../../secrets.yaml;
    owner = "fbartik";
    group = "users";
    path = "/home/fbartik/.kube/config";
  };

  home-manager.users.fbartik = import ../../../../home/fbartik/${config.networking.hostName}.nix;

  security.pam = {
    # rssh allows approving sudo using the ssh-agent (in my case 1password)
    rssh.enable = true;
    services.sudo.rssh = true;
  };
}
