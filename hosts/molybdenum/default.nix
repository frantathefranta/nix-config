{
  imports = [
    #./services
    ./dn42
    ./hardware-configuration.nix

    ../common/global
    ../common/optional/qemu-guest-agent.nix
    #../common/optional/1password.nix
    ../common/users/fbartik
  ];
  networking = {
    hostName = "molybdenum";
    useDHCP = false;
    interfaces.ens18 = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = "10.32.10.242";
          prefixLength = 24;
        }
      ];
      ipv6.addresses = [
        {
          address = "2600:1702:6630:3fed::242";
          prefixLength = 64;
        }
      ];
    };
    defaultGateway = {
      address = "10.32.10.254";
      interface = "ens18";
    };
  };
  system.stateVersion = "25.05";
}
