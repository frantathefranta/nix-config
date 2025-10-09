{
  imports = [
    ./hardware-configuration.nix
    # ../common/users/fbartik
  ];
  networking = {
    hostName = "r2s";
    useDHCP = true;
  };
  system.stateVersion = "25.05";
  system.enableExtlinuxTarball = true;
}
