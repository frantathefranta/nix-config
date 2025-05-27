{
  imports = [
    ./hardware-configuration.nix
    ../common/global
    ../common/optional/qemu-guest-agent.nix
    ../common/users/fbartik
  ];
  networking = {
    hostName = "nix-bastion";
    useDHCP = true;
    dhcpcd.IPv6rs = true;
    interfaces.ens18 = {
      useDHCP = true;
      tempAddress = "disabled";
    };
  };
  system.stateVersion = "24.11";
}
