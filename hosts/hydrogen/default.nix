{
  inputs,
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
    ../common/roles/server.nix

    ../common/optional/fwupd.nix
    ../common/optional/secure-boot.nix
  ];
  networking = {
    hostName = "hydrogen";
    domain = "infra.franta.us";
    domains.subDomains = {
      "${config.networking.hostName}.${config.networking.domain}" = {
        a.data = [ "10.32.10.90" ];
        aaaa.data = [ "2600:1702:6630:3fed:10:32:10:90" ];
      };
    };
  };
  networking.nameservers = [ "10.0.10.1" ];

  services.prometheus.exporters.node.listenAddress = "0.0.0.0";
  systemd.network.enable = true;

  systemd.network.networks."10-enp2s0" = {
    matchConfig.Name = "enp2s0";
    address = [ "10.32.10.90/24" ];
    networkConfig = {
      IPv6AcceptRA = true;
      IPv6PrivacyExtensions = false;
      EmitLLDP = true;
    };
    ipv6AcceptRAConfig = {
      Token = "::10:32:10:90";
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
    ipv4 = "10.32.10.90";
    ipv6Suffix = "10:32:10:90";
  };
  time.timeZone = "America/Detroit";
  system.stateVersion = "26.05";
}
