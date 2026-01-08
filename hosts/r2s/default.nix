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
    nameservers = [ "1.1.1.1" "1.0.0.1" ];
  };
  system.stateVersion = "25.05";
  system.enableExtlinuxTarball = true;
  documentation.man.generateCaches = false;
  time.timeZone = "Europe/Prague";

}
