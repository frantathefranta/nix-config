{
  inputs,
  lib,
  config,
  ...
}: {
  imports = [
    inputs.hardware.nixosModules.common-cpu-intel
    inputs.hardware.nixosModules.common-pc-ssd

    ./hardware-configuration.nix

    ../common/global
    ../common/users/fbartik
    ../common/roles/server.nix
    ../common/optional/secure-boot.nix
  ];

  hardware.facter.reportPath = ./facter.json;

  networking = {
    hostName = "neon";
    domain = "infra.franta.us";
  };

  systemd.network.enable = true;

  systemd.network.networks."10-mgmt" = {
    matchConfig.Name = "enp0s31f6";
    address = [ "${config.meta.ipam.host.ipv4}/24" ];
    networkConfig = {
      IPv6AcceptRA = true;
      EmitLLDP = true;
    };
    ipv6AcceptRAConfig = {
      Token = "::${config.meta.ipam.host.ipv6Suffix}";
    };
    dns = config.networking.nameservers;
    domains = [
      "internal"
      "franta.us"
      "infra.franta.us"
    ];
    routes = [
      {
        Gateway = "10.32.10.254";
        Destination = "0.0.0.0/0";
      }
    ];
  };

  meta.ipam.host = {
    ipv4 = "10.32.10.92";
    ipv6Suffix = "10:32:10:92";
    macAddress = "";
  };


  time.timeZone = "America/Detroit";
  system.stateVersion = "26.05";
}
