{ lib, pkgs, config, ... }:
let
  lo_ipv6 = "2600:1702:6630:3fec::10:11";
in
{
  imports = [
    ./hardware-configuration.nix

    ../common/global
    ../common/roles/server.nix
    ../common/optional/qemu-guest-agent.nix
    ../common/optional/1password.nix
    ../common/users/fbartik
    ./services
  ];
  networking = {
    hostName = "nix-bastion";
    useDHCP = false;
    enableIPv6 = true;
    domains.subDomains."${config.networking.hostName}.${config.networking.domain}" = {
      a.data = [ "10.32.10.11" ];
      aaaa.data = [ "2600:1702:6630:3fed:10:32:10:11" ];
    };
    firewall.interfaces.ens18 = {
      allowedTCPPorts = [
        80
        443
      ];
    };
  };
  # The networking.nameservers get prepended to /etc/resolv.conf, defeating the purpose of selecting a DNS server per domain
  networking.nameservers = [ ];

  time.timeZone = "America/Detroit";
  security.pki.certificateFiles = [ "${pkgs.dn42-cacert}/etc/ssl/certs/dn42-ca.crt" ];
  users.groups = {
    media = {
      gid = 1003;
      members = [ "fbartik" ];
    };
  };
  systemd.network.enable = true;

  systemd.network.networks."10-lo" = {
    matchConfig.Name = "lo";
    address = [
      "10.0.10.11/32"
      "${lo_ipv6}/128"
    ];
    # Linux doesn't add lo route to main routing table by default
    routes = [
      { Destination = "10.0.10.11/32"; }
    ];
  };

  systemd.network.networks."10-ens18" = {
    matchConfig.Name = "ens18";
    address = [ "10.32.10.11/24" ];
    networkConfig = {
      IPv6AcceptRA = true;
      IPv6PrivacyExtensions = false;
    };
    ipv6AcceptRAConfig = {
      Token = "::10:32:10:11";
    };
    dns = [ "10.0.10.1" ];
    domains = [
      "franta.us"
      "infra.franta.us"
    ];
    routes = [
      {
        Gateway = "10.32.10.254";
        Destination = "0.0.0.0/0";
      }
    ];
    vlan = [ "ens18.2000" ];
  };
  systemd.network = {
    netdevs."20-ens18.2000" = {
      netdevConfig = {
        Name = "ens18.2000";
        Description = "DN42 DHCP";
        Kind = "vlan";
      };
      vlanConfig.Id = 2000;
    };
    networks."20-ens18.2000" = {
      matchConfig.Name = "ens18.2000";
      networkConfig = {
        IPv6AcceptRA = true;
        IPv6PrivacyExtensions = false;
      };
      ipv6AcceptRAConfig = {
        Token = "::10:32:10:11";
      };
    };
  };
  services.prometheus.exporters.node = {
    listenAddress = "10.32.10.11";
  };

  meta.ipam.host = {
    ipv4 = "10.32.10.11";
    ipv6Suffix = "10:32:10:11";
  };
  security.sudo.wheelNeedsPassword = lib.mkForce true;

  system.stateVersion = "24.11";
}
