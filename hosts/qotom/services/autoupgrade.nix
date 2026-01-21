{ config, lib, pkgs, ... }:

{
  system.autoUpgrade = {
    enable = true;
    flake = "github:frantathefranta/nix-config#${config.networking.hostName}";
    flags = [
      "--print-build-logs"
      "--accept-flake-config"
    ];
    dates = "Mon 05:00";
    randomizedDelaySec = "30min";
  };
}
