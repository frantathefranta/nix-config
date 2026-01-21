{ config, lib, pkgs, ... }:

{
  
  imports = [
    ./bird.nix
    ./peers/wireguard.nix
  ];
  environment.systemPackages = [ pkgs.wireguard-tools ];
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.rp_filter" = 0;
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv4.conf.default.rp_filter" = 0;
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv4.tcp_l3mdev_accept" = 1;
    "net.ipv4.udp_l3mdev_accept" = 1;
  };
  systemd.network.enable = true;
  systemd.network.netdevs."20-vrf_dn42" = {
    netdevConfig = {
      Name = "dn42";
      Kind = "vrf";
    };
    vrfConfig = {
      Table = 4242;
    };
  };
  systemd.network.networks."20-vrf_dn42" = {
    matchConfig.Name = "dn42";
    linkConfig = {
      ActivationPolicy = "up";
      RequiredForOnline = false;
    };
  };
  systemd.network.netdevs."30-dummy42" = {
    netdevConfig = {
      Name = "dummy42";
      Kind = "dummy";
    };
  };
  systemd.network.networks."30-dummy42" = {
    matchConfig.Name = "dummy42";
    address = [
      "172.23.234.19"
      "fdb7:c21f:f30f:2::1/128"
    ];
    linkConfig = {
      ActivationPolicy = "up";
      RequiredForOnline = false;
    };
    networkConfig = {
      LinkLocalAddressing = false;
      IPv6LinkLocalAddressGenerationMode = "none";
      DNSDefaultRoute = false;
      VRF = "dn42";
    };
    dns = [
     "172.23.234.30" 
     "fdb7:c21f:f30f:53::" 
    ];
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
  services.custom-wireguard.interfaces = {
    "50-ospf_molybdenum" = {
      listenPort = 24003;
      peerEndpoint = "cmh.dn42.franta.us:24001";
      peerPublicKey = "+ussih60DoaN4k+jwheyo7iMAEBN+Ns69A4Km2E8pEg=";
      localAddressV6 = "fe80::2:1033/64";
      peerAddressV6 = "fe80::1033";
      isOSPF = true;
      localAddressV4 = "169.254.2.0/31";
      peerAddressV4 = "169.254.2.1/31";
      vrf = "dn42";
    };
    "50-ospf_hetzner" = {
      listenPort = 24002;
      peerEndpoint = "pdx.dn42.franta.us:24002";
      peerPublicKey = "tSHnY/aezSgH6p5E2tMQCQWDMe4hTAcv9cKkq/qJwkk=";
      localAddressV6 = "fe80::2:1033/128";
      peerAddressV6 = "fe80::1:1033/128";
      isOSPF = true;
      localAddressV4 = "169.254.1.0/31";
      peerAddressV4 = "169.254.1.1/31";
      vrf = "dn42";
    };
  };
  networking.firewall.extraInputRules = ''
    ip protocol ospfigp counter accept
    ip6 nexthdr ospfigp counter accept
    ip saddr 172.20.0.0/14 counter accept
    ip6 saddr fd00::/8 counter accept
    ip6 saddr fe80::/64 counter accept
  '';
}
