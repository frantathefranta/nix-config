{ config, lib, pkgs, ... }:

{
  virtualisation.podman = {
    enable = true;
    autoPrune = {
      enable = true;
    };
  };
  users.groups.podman.members = [ config.users.users.fbartik.name ];
}
