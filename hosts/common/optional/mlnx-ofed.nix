{
  inputs,
  pkgs,
  ...
}:

{
  imports = [
    # Add packages from this repo and set up binary cache
    inputs.mlnx-ofed-nixos.nixosModules.setupCacheAndOverlays
    # Add configuration options from this repo
    inputs.mlnx-ofed-nixos.nixosModules.default
  ];
  environment.systemPackages = [ pkgs.mstflint ];
  hardware.mlnx-ofed = {
    enable = true;
    # nvme.enable = true;
    # nfsrdma.enable = true;
    kernel-mft.enable = true;
  };
}
