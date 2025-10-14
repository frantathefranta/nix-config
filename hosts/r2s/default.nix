{
  imports = [
    ./hardware-configuration.nix
    ./networking.nix
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
