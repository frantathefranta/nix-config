{ inputs, pkgs, ... }:
{
  imports = [
    inputs.hardware.nixosModules.common-cpu-intel
    inputs.hardware.nixosModules.common-pc-ssd
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
  # environment.systemPackages = with pkgs; [
  #   conman
  # ];
  system.stateVersion = "24.11";
}
