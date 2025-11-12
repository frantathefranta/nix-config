{ lib, inputs, ... }:
{
  imports = [
    inputs.hardware.nixosModules.common-cpu-intel
    inputs.hardware.nixosModules.common-pc-ssd
    ./services
    ./hardware-configuration.nix

    ../common/global
    ../common/users/fbartik

    ../common/optional/smartd.nix
  ];
  networking = {
    hostName = "qotom";
    useDHCP = false;
    interfaces.enp1s0 = {
      ipv4.addresses = [
        {
          address = "10.32.10.10";
          prefixLength = 24;
        }
      ];
      ipv6.addresses = [
        {
          address = "2600:1702:6630:3fed:10:32:10:10";
          prefixLength = 64;
        }
      ];
    };
    interfaces.wlp2s0.ipv4 = {
      addresses = [
        {
          address = "172.32.254.1";
          prefixLength = 27;
        }
      ];
    };
    defaultGateway = {
      address = "10.32.10.254";
      interface = "enp1s0";
    };
    defaultGateway6 = {
      address = "fe80::464c:a8ff:fede:3cf7";
      interface = "enp1s0";
    };
  };
  # networking.resolvconf.extraOptions = [
  #   "nameserver ::1"
  # ];
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.rp_filter" = 0;
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv4.conf.default.rp_filter" = 0;
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };
  services.resolved.extraConfig = ''
    DNSStubListenerExtra=[::1]:53
  '';
  environment.etc."resolv.conf".source = lib.mkForce "/run/systemd/resolve/stub-resolv-custom.conf";
  systemd.tmpfiles.settings.custom-resolvconf."/run/systemd/resolve/stub-resolv-custom.conf" = {
    f = {
      argument = "nameserver ::1 \n nameserver 127.0.0.53\n options edns0 trust-ad\n search .";
      user = "systemd-resolve";
      group = "systemd-resolve";
      mode = "0644";
      type = "f";
    };
  };
  # systemd.tmpfiles.rules = [
  #     "f /run/systemd/resolve/stub-resolv-custom.conf 0644 systemd-resolve systemd-resolve - nameserver ::1
  #           nameserver 127.0.0.53
  #           options edns0 trust-ad
  #           search ."
  # ];
  systemd.network.enable = true;
  systemd.services.systemd-resolved.serviceConfig = {
    Environment = "SYSTEMD_LOG_LEVEL=debug";
  };
  systemd.network.netdevs."10-dummy42" = {
    netdevConfig = {
      Name = "dummy42";
      Kind = "dummy";
    };
  };
  systemd.network.networks."10-dummy42" = {
    matchConfig.Name = "dummy42";
    address = [
      "172.23.234.20/32"
      "fdb7:c21f:f30f:10::10/128"
    ];
    networkConfig = {
      LinkLocalAddressing = false;
      IPv6LinkLocalAddressGenerationMode = "none";
      DNS = "fdb7:c21f:f30f:53::";
      # DNS="172.23.234.17 fdb7:c21f:f30f:53::";
      # DNS="fd42:d42:d42:54::1";
      DNSDefaultRoute = false;
      Domains = "dn42";
    };
  };
  system.stateVersion = "24.11";
}
