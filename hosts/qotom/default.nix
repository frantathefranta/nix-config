{
  imports = [
    ./hardware-configuration.nix

    ../common/global
    ../common/users/fbartik
  ];
  networking = {
    hostName = "qotom";
    useDHCP = true;
  };
  system.stateVersion = "24.11"
}
