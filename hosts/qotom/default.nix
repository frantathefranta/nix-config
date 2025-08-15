{ pkgs, ... }:
{
  imports = [
    ./services
    ./hardware-configuration.nix

    ../common/global
    ../common/users/fbartik
    ../common/optional/fwupd.nix
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
  environment.systemPackages = with pkgs; [
    conman
  ];
  system.stateVersion = "24.11";
}
