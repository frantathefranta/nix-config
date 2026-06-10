{
  inputs,
  pkgs,
  config,
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
    # ../common/roles/server.nix

    ../common/optional/fwupd.nix
  ];
  networking = {
    hostName = "nixos-firewall";
    domain = "infra.franta.us";
    domains.subDomains = {
      "${config.networking.hostName}-lan0.${config.networking.domain}" = {
        a.data = [ "10.0.10.1" ];
        aaaa.data = [ "2600:1702:6630:3fe0:10:0:10:1" ];
      };
      "${config.networking.hostName}-mgmt.${config.networking.domain}" = {
        a.data = [ "10.32.10.230" ];
        aaaa.data = [ "2600:1702:6630:3fed:10:32:10:230" ];
      };
      "${config.networking.hostName}.${config.networking.domain}".cname.data = "${config.networking.hostName}-lan0";
      "time.${config.networking.domain}".cname.data = "${config.networking.hostName}";
      "logs.${config.networking.domain}".cname.data = "${config.networking.hostName}";
      "nut.${config.networking.domain}".cname.data = "${config.networking.hostName}";
    };
  };
  time.timeZone = "America/Detroit";
  environment.systemPackages = [
    pkgs.i2c-tools
    pkgs.vep14xx-diags
  ];
  documentation.man.man-db.enable = false;
  system.stateVersion = "25.11";
}
