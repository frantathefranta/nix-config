{
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    inputs.hardware.nixosModules.common-cpu-intel
    inputs.hardware.nixosModules.common-pc-ssd
    ./services
    ./hardware-configuration.nix

    ../common/global
    ../common/users/fbartik
    ../common/roles/server.nix

    ../common/optional/fwupd.nix
  ];
  networking = {
    hostName = "nixos-firewall";
  };
  time.timeZone = "America/Detroit";
  environment.systemPackages = [
    pkgs.i2c-tools
    pkgs.vep14xx-diags
  ];
  system.stateVersion = "25.11";
}
