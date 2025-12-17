{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:

{
  imports = [
    inputs.hardware.nixosModules.rock-pi-4
    # "${inputs.hardware.outPath}/rockchip/disko.nix"
    inputs.disko.nixosModules.disko
    ./hardware-configuration.nix
    # ./networking.nix
    ../common/global
    ../common/users/fbartik
  ];
  
  networking = {
    hostName = "radxa-eu";
    useDHCP = true;
  };
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "25.11";
  documentation.man.generateCaches = false;
}
