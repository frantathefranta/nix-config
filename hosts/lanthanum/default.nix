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
    ./networking.nix

    ../common/global
    ../common/users/fbartik

    ../common/optional/kde.nix
    ../common/optional/1password.nix
    ../common/optional/fwupd.nix
  ];
  networking = {
    hostName = "lanthanum";
    useDHCP = false;
    hosts = {
      "10.254.0.63" = [
        "r2s"
        "r2s.infra.franta.us"
      ];
    };
    interfaces.wlp9s0.useDHCP = true;
  };

  programs = {
    dconf.enable = true;
    steam.enable = true;
  };
  services.xserver.videoDrivers = [ "nvidia" ];
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
    libftdi.enable = false;
    keyboard.qmk.enable = true;
  };
  environment.systemPackages = with pkgs; [
    nvme-cli
    vial
    via
    qmk
    # lattice-diamond
    #    libusb1
    #    libusb-compat-0_1
  ];
  services.udev.packages = with pkgs; [
    vial
    via
    f2fs-tools # Interacting with R2s filesystem
  ];
  fonts.packages = with pkgs; [
    etBembo
  ];
  system.stateVersion = "24.11";
}
