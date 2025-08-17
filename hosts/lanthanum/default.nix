{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.hardware.nixosModules.common-cpu-amd
    inputs.hardware.nixosModules.common-pc-ssd
    ./services
    ./hardware-configuration.nix

    ../common/global
    ../common/users/fbartik

    ../common/optional/kde.nix
    ../common/optional/1password.nix
    ../common/optional/fwupd.nix
  ];
  networking = {
    hostName = "lanthanum";
    useDHCP = true;
    dhcpcd.IPv6rs = true;
    interfaces.eno1 = {
      useDHCP = true;
    };
    firewall.interfaces.enp1s0.allowedTCPPorts = [
      22000
    ];
    firewall.interfaces.enp1s0.allowedUDPPorts = [
      21027
      22000
    ];
  };

  programs = {
    dconf.enable = true;
    steam.enable = true;
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
    enableAllFirmware = true;
  };
  services.udev.packages = with pkgs; [
    vial
    via
  ];
  system.stateVersion = "24.11";
}
