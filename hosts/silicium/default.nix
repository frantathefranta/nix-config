{ inputs, pkgs, ... }:

{
  imports = [
    inputs.hardware.nixosModules.lenovo-thinkpad-t14-amd-gen1
    ./hardware-configuration.nix
    ./services
    ../common/global
    ../common/users/fbartik
    ../common/roles/workstation.nix

    ../common/optional/kde.nix
    ../common/optional/fwupd.nix
    ../common/optional/evremap.nix
  ];
  networking = {
    hostName = "silicium";
    nameservers = [ ];
    useNetworkd = true;
  };
  systemd = {
    network = {
      enable = true;
      wait-online.enable = false;
      networks."30-wlp3s0" = {
        matchConfig.Name = "wlp3s0";
        networkConfig = {
          DHCP = "ipv4";
          IPv6AcceptRA = true;
        };
      };
    };
  };

  hardware.enableAllFirmware = true;
  services.fprintd.enable = true;

  nixpkgs.overlays = [ inputs.nix-cachyos-kernel.overlays.pinned ];
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-x86_64-v3;
  # Binary cache
  nix.settings.substituters = [ "https://attic.xuyh0120.win/lantian" ];
  nix.settings.trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];
  system.stateVersion = "25.11";
}
