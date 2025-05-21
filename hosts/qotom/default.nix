{
  imports = [
    ./services
    ./hardware-configuration.nix

    ../common/global
    ../common/users/fbartik
  ];
  networking = {
    hostName = "qotom";
    useDHCP = true;
    interfaces.wlp2s0.ipv4 = {
      addresses = [
        {
          address = "172.32.254.1";
          prefixLength = 27;
        }
      ];
    };
  };
  system.stateVersion = "24.11";
}
