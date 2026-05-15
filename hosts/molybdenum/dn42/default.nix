{ ... }:
{
  imports = [
    ./wireguard.nix
    ./bird2.nix
    ./bind.nix
    ./caddy.nix
    ./peers/wireguard.nix
  ];

  boot.kernel.sysctl = {
    "net.ipv4.conf.all.rp_filter" = 0;
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv4.conf.default.rp_filter" = 0;
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  networking = {
    firewall = {
      checkReversePath = false;
      interfaces.ens18.allowedUDPPortRanges = [
        {
          from = 20000;
          to = 30000;
        }
      ];
      extraInputRules = /* nftables */ ''
        ip saddr 172.20.0.0/14 counter accept
        ip6 saddr fd00::/8 counter accept
        ip6 saddr fe80::/64 counter accept
        ip saddr 10.33.0.0/16 accept
        ip saddr 10.32.10.0/24 accept
        ip6 saddr 2600:1702:6630:3fec::/62 accept
        ip6 saddr 2600:1702:6630:3fe4::/64 accept
      '';
    };
    nftables = {
      enable = true;
    };
    interfaces.lo = {
      ipv4.addresses = [
        {
          address = "172.23.234.17";
          prefixLength = 32;
        }
      ];
      ipv6.addresses = [
        {
          address = "fdb7:c21f:f30f::1";
          prefixLength = 128;
        }
      ];
    };
  };
  systemd.network.enable = true;
  systemd.network.netdevs."10-dummy53" = {
    netdevConfig = {
      Name = "dummy53";
      Kind = "dummy";
    };
  };
  systemd.network.networks."10-dummy53" = {
    matchConfig.Name = "dummy53";
    address = [
      "172.23.234.30/32"
      "fdb7:c21f:f30f:53::/128"
    ];
    networkConfig = {
      LinkLocalAddressing = false;
      DNS = "fdb7:c21f:f30f:53::";
      DNSDefaultRoute = false;
    };
    domains = [
      "~dn42"
      "~20.172.in-addr.arpa"
      "~21.172.in-addr.arpa"
      "~22.172.in-addr.arpa"
      "~23.172.in-addr.arpa"
      "~10.in-addr.arpa"
      "~d.f.ip6.arpa"
    ];
  };
  systemd.network.netdevs = {
    "20-ens18.2000" = {
      netdevConfig = {
        Name = "ens18.2000";
        Description = "DN42 DHCP";
        Kind = "vlan";
      };
      vlanConfig.Id = 2000;
    };
  };
  systemd.network.networks = {
    "20-ens18.2000" = {
      matchConfig.Name = "ens18.2000";
      networkConfig = {
        IPv6AcceptRA = false;
        IPv6SendRA = true;
        IPv6PrivacyExtensions = false;
      };
      ipv6SendRAConfig = {
        RouterLifetimeSec = 0; # Don't advertise a default route. Doesn't interfere with ipv6RoutePrefixes
        DNS = "fdb7:c21f:f30f:53::";
      };
      ipv6Prefixes = [ { Prefix = "fdb7:c21f:f30f:0099::/64"; } ];
      ipv6RoutePrefixes = [ { Route = "fd00::/8"; } ];
      addresses = [ { Address = "fdb7:c21f:f30f:0099:172:23:234:17/64"; } ];
      domains = [
        "~dn42"
        "~d.f.ip6.arpa"
      ];
    };
  };
}
