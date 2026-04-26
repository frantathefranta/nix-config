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
    ../common/roles/workstation.nix

    ../common/optional/kde.nix
    ../common/optional/fwupd.nix
  ];
  networking = {
    hostName = "lanthanum";
    useDHCP = false;
    # hosts = {
    #   "10.254.0.63" = [
    #     "r2s"
    #     "r2s.infra.franta.us"
    #   ];
    # };
    interfaces.wlp9s0.useDHCP = true;
  };

  programs = {
    dconf.enable = true;
steam = {
    enable = true;
    remotePlay.openFirewall = true;
};
    gamescope = {
      enable = true;
      capSysNice = false;
    };
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
  ];
  fonts.packages = with pkgs; [
    etBembo
  ];

  nixpkgs.overlays = [ inputs.nix-cachyos-kernel.overlays.pinned ];
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-zen4;
  # Binary cache
  nix.settings.substituters = [ "https://attic.xuyh0120.win/lantian" ];
  nix.settings.trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];
  system.stateVersion = "24.11";
}
