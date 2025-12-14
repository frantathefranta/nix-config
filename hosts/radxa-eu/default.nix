{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:

{
  imports = [
    inputs.hardware.nixosModules.radxa-rock-pi-4
    inputs.nixos-rockhip.nixosModules.sdImageRockchip
    ./hardware-configuration.nix
    ./networking.nix
    # ../common/global
    # ../common/users/fbartik
  ];

  # system.build.raw = pkgs.callPackage (pkgs.path + "/nixos/lib/make-disk-image.nix") {
  #   inherit pkgs lib config; # We inherit the config.

  #   partitionTableType = "hybrid"; # Hybrid means we support both MBR and UEFI boot.
  #   label = "nixos";
  #   diskSize = "auto";
  #   format = "raw";
  # };
  networking = {
    hostName = "radxa-eu";
  };
  system.stateVersion = "25.11";
  documentation.man.generateCaches = false;
}
