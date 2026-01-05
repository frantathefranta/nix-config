{ inputs, ... }:
{
  imports = [
    inputs.eh5.nixosModules.fake-hwclock
    ./hardware-configuration.nix
    ./networking.nix
    # ./services
    ../common/global
    ../common/users/fbartik
  ];
  networking = {
    hostName = "r2s";
  };
  system.stateVersion = "25.05";
  system.enableExtlinuxTarball = true;
  documentation.man.generateCaches = false;
}
