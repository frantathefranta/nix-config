{ pkgs, ... }:
{
  imports = [
    ./wireguard.nix
    ./bird2.nix
    ./bind.nix
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
      extraCommands = ''
        ${pkgs.iptables}/bin/iptables -A INPUT -s 10.33.00.0/16 -j ACCEPT
        ${pkgs.iptables}/bin/iptables -A INPUT -s 10.32.10.0/24 -j ACCEPT
        ${pkgs.iptables}/bin/iptables -A INPUT -s 172.20.0.0/14 -j ACCEPT
        ${pkgs.iptables}/bin/ip6tables -A INPUT -s fd00::/8 -j ACCEPT
        ${pkgs.iptables}/bin/ip6tables -A INPUT -s fe80::/64 -j ACCEPT
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
          address = "fdb7:c21f:f30f::";
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
      # IPv6LinkLocalAddressGenerationMode = "none";
      # DNS = "fdb7:c21f:f30f:53::";
      # DNS="172.23.234.17 fdb7:c21f:f30f:53::";
      # DNS="fd42:d42:d42:54::1";
      DNSDefaultRoute = false;
      # Domains = "dn42";
    };
  };
}
