{
  imports = [
    ./services
    ./hardware-configuration.nix

    ../common/global
    ../common/optional/qemu-guest-agent.nix
    ../common/optional/1password.nix
    ../common/users/fbartik
  ];
  networking = {
    hostName = "nix-bastion";
    useDHCP = true;
    dhcpcd.IPv6rs = true;
    interfaces.ens18 = {
      useDHCP = true;
    };
  };
  system.stateVersion = "24.11";
}
