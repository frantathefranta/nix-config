{
  inputs,
  config,
  ...
}:
{
  imports = [
    inputs.hardware.nixosModules.common-cpu-intel
    inputs.hardware.nixosModules.common-pc-ssd
    inputs.disko.nixosModules.disko
    ./disko.nix

    ../common/global
    ../common/users/fbartik
    ../common/roles/server.nix

    ../common/optional/fwupd.nix
    ../common/optional/secure-boot.nix
  ];

  hardware.facter.reportPath = ./facter.json;

  networking = {
    hostName = "ytterbium";
    domain = "infra.franta.us";
    domains.subDomains = {
      "${config.networking.hostName}.${config.networking.domain}" = {
        a.data = [ config.meta.ipam.host.ipv4 ];
        aaaa.data = [ "2600:1702:6630:3fed:${config.meta.ipam.host.ipv6Suffix}" ];
      };
    };
  };
  networking.nameservers = [ "10.0.10.1" ];

  services.prometheus.exporters.node.listenAddress = "0.0.0.0";
  systemd.network.enable = true;

  systemd.network.networks."10-enp0s31f6" = {
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
    ipv4 = "10.32.10.91";
    ipv6Suffix = "10:32:10:91";
  };
  time.timeZone = "America/Detroit";

  system.stateVersion = "26.05";
}
