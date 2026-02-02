{ inputs, ... }:

{
  imports = [
    inputs.hardware.nixosModules.lenovo-thinkpad-t14-amd-gen1
    ./hardware-configuration.nix
    ./services
    ../common/global
    ../common/users/fbartik

    ../common/optional/kde.nix
    ../common/optional/1password.nix
    ../common/optional/fwupd.nix
  ];
  networking = {
    hostName = "silicium";
    useDHCP = true;
  };
  interfaces.wlp3s0.useDHCP = true;
  # hardware.enableAllFirmware = true;
  system.stateVersion = "25.11";
}
