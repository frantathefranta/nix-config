{
  inputs,
  ...
}:
{
  imports = [
    inputs.hardware.nixosModules.common-cpu-intel
    inputs.hardware.nixosModules.common-pc-ssd
    ./services
    ./hardware-configuration.nix

    ../common/global
    ../common/users/fbartik

    ../common/optional/fwupd.nix
  ];
  networking = {
    hostName = "nixos-firewall";
  };
  system.stateVersion = "25.11";
}
