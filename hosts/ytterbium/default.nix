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
    ./services

    ../common/global
    ../common/users/fbartik
    ../common/roles/server.nix

    ../common/optional/fwupd.nix
    ../common/optional/secure-boot.nix
    ../common/optional/initrd-ssh.nix
    ../common/optional/mlnx-ofed.nix
  ];

  hardware.facter.reportPath = ./facter.json;
  boot.kernelParams = [ "console=ttyS1,115200n8" ];

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

  systemd.network.networks."10-enp1s0np0" = {
    matchConfig.Name = "enp1s0np0";
    linkConfig.MTUBytes = 9000;
    networkConfig = {
      Address = "";
      EmitLLDP = true;
      IPv4Forwarding = true;
      IPv6Forwarding = true;
    };
  };

  systemd.network.networks."10-lo" = {
    matchConfig.Name = "lo";
    address = [
      "10.0.0.91/32"
      "2600:1702:6630:3fea::91/128"
    ];
  };

  services.frr = {
    bgpd.enable = true;
    config = ''
      router bgp 65100
        bgp router-id 10.0.0.91
        bgp log-neighbor-changes
        no bgp ebgp-requires-policy
        no bgp hard-administrative-reset
        no bgp graceful-restart notification
        no bgp network import-check
        neighbor enp1s0np0 interface remote-as auto
        neighbor enp1s0np0 capability extended-nexthop
        address-family ipv4 unicast
          network 10.0.0.91/32
          network 2600:1702:6630:3fea::91/128
        exit-address-family
        address-family ipv6 unicast
          neighbor enp1s0np0 activate
        exit-address-family
      ip prefix-list loopbacks_ips seq 10 permit 0.0.0.0/0 ge 32
      route-map correct_src_ipv4 permit 1
        set src 10.0.0.91
      route-map correct_src_ipv6 permit 1
        set src 2600:1702:6630:3fea::91
      ip protocol bgp route-map correct_src_ipv4
      ipv6 protocol bgp route-map correct_src_ipv6
    '';
  };

  meta.ipam.host = {
    ipv4 = "10.32.10.91";
    ipv6Suffix = "10:32:10:91";
    macAddress = "08:92:04:e0:da:9d";
  };
  time.timeZone = "America/Detroit";

  system.stateVersion = "26.05";
}
