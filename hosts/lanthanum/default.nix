{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.hardware.nixosModules.common-cpu-amd
    # inputs.hardware.nixosModules.common-gpu-nvidia
    inputs.hardware.nixosModules.common-pc-ssd
    ./services
    ./hardware-configuration.nix

    ../common/global
    ../common/users/fbartik

    ../common/optional/kde.nix
    ../common/optional/1password.nix
  ];
  networking = {
    hostName = "lanthanum";
    useDHCP = true;
    dhcpcd.IPv6rs = true;
    interfaces.ens18 = {
      useDHCP = true;
    };
  };
  programs = {
    dconf.enable = true;
  };
  hardware = {
    graphics.enable = true;
    nvidia.modesetting.enable = true;
    nvidia.open = true;
    nvidia.powerManagement.enable = true;
    nvidia.nvidiaPersistenced = true;

    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };
  system.stateVersion = "24.11";
}
