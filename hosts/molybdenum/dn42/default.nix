{ pkgs, ... }:
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
    };
    nftables = {
      enable = true;
      ruleset = ''
        table inet dn42filter {
          chain input {
            type filter hook input priority filter; policy accept;
            
            # Accept DN42 traffic
            ip saddr 172.20.0.0/14 accept
            ip6 saddr fd00::/8 accept
            ip6 saddr fe80::/64 accept
          }
        }
        table inet local_subnets {
          chain input {
            type filter hook input priority filter; policy accept;
            ip saddr 10.33.0.0/16 accept
            ip saddr 10.32.10.0/24 accept
            ip6 saddr 2600:1702:6630:3fec::/63 accept
          }
        }
      '';
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
      Domains = "~dn42";
      DNSDefaultRoute = false;
    };
  };
  # systemd.network.netdevs."10-dummy_ospf" = {
  #   netdevConfig = {
  #     Name = "dummy_ospf";
  #     Kind = "dummy";
  #   };
  # };
  # systemd.network.networks."10-dummy_ospf" = {
  #   matchConfig.Name = "dummy_ospf";
  #   address = [
  #     "fdb7:c21f:f30f::89/128"
  #   ];
  #   networkConfig = {
  #     LinkLocalAddressing = false;
  #   };
  # };
}
