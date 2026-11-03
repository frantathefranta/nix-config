{
  inputs,
  lib,
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
    ../common/optional/secure-boot.nix
  ];

  hardware.facter.reportPath = ./facter.json;

  networking = {
    hostName = "neon";
    domain = "infra.franta.us";
    firewall.allowedUDPPorts = [ 5353 ]; # mDNS on all interfaces (IPv4 and IPv6).
    domains.subDomains = {
      "${config.networking.hostName}.${config.networking.domain}" = {
        a.data = [ config.meta.ipam.host.ipv4 ];
        aaaa.data = [ "2600:1702:6630:3fed:${config.meta.ipam.host.ipv6Suffix}" ];
      };
    };
  };

  services.resolved = {
    enable = true;
    settings.Resolve.MulticastDNS = "resolve";
  };

services.comin.autoReboot = true;

  systemd.network.enable = true;

  systemd.network.netdevs = lib.listToAttrs (
    map (
      id:
      lib.nameValuePair "20-eno3.${toString id}" {
        netdevConfig = {
          Name = "eno3.${toString id}";
          Kind = "vlan";
        };
        vlanConfig.Id = id;
      }
    ) [ 20 50 ]
  );

  systemd.network.networks = {
    "05-disabled" = {
      matchConfig.Name = "eno1 eno2";
      linkConfig = {
        ActivationPolicy = "always-down";
        RequiredForOnline = false;
      };
      networkConfig = {
        DHCP = "no";
        IPv6AcceptRA = false;
        LinkLocalAddressing = "no";
      };
    };

    "10-vlan-trunk" = {
      matchConfig.Name = "eno3";
      vlan = [
        "eno3.20"
        "eno3.50"
      ];
      networkConfig = {
        DHCP = "no";
        IPv6AcceptRA = false;
        LinkLocalAddressing = "no";
      };
    };

    "10-mgmt" = {
      matchConfig.Name = "eno4";
      address = [ "${config.meta.ipam.host.ipv4}/24" ];
      networkConfig = {
        IPv6AcceptRA = true;
        EmitLLDP = true;
        MulticastDNS = "resolve";
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
  } // lib.listToAttrs (
    map (
      id:
      lib.nameValuePair "20-eno3.${toString id}" {
        matchConfig.Name = "eno3.${toString id}";
        address = [ "10.0.${toString id}.92/24" ];
        networkConfig = {
          DHCP = "no";
          IPv6AcceptRA = true;
          IPv6PrivacyExtensions = false;
          IPv4Forwarding = false;
          IPv6Forwarding = false;
          DNSDefaultRoute = false;
          MulticastDNS = "resolve";
        };
        # Learn only SLAAC addresses and on-link prefixes, never router routes.
        ipv6AcceptRAConfig = {
          Token = "::10:0:${toString id}:92";
          UseGateway = false;
          UseRoutePrefix = false;
          UseDNS = false;
          UseDomains = false;
          DHCPv6Client = false;
        };
      }
    ) [ 20 50 ]
  );

  meta.ipam.host = {
    ipv4 = "10.32.10.92";
    ipv6Suffix = "10:32:10:92";
    macAddress = "18:5a:58:c2:74:63";
  };

  time.timeZone = "America/Detroit";
  system.stateVersion = "26.05";
}
