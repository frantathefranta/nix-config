{ ... }:
let
  hostIPv4 = "10.32.10.242";
in
{
  imports = [
    #./services
    ./dn42
    ./hardware-configuration.nix

    ../common/global
    ../common/roles/server.nix
    ../common/optional/dn42.nix
    ../common/optional/qemu-guest-agent.nix
    ../common/optional/autoupgrade.nix
    #../common/optional/1password.nix
    ../common/users/fbartik
  ];
  networking = {
    hostName = "molybdenum";
    useDHCP = false;
    interfaces.ens18 = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = hostIPv4;
          prefixLength = 24;
        }
      ];
      ipv6.addresses = [
        {
          address = "2600:1702:6630:3fed::242";
          prefixLength = 64;
        }
      ];
    };
    defaultGateway = {
      address = "10.32.10.254";
      interface = "ens18";
    };
    defaultGateway6 = {
      address = "fe80::464c:a8ff:fede:3cf7";
      interface = "ens18";
    };
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
      "2606:4700:4700::1111"
      "2606:4700:4700::1001"
    ];
  };
  time.timeZone = "America/Detroit";
  services.prometheus.exporters.node = {
    openFirewall = true;
    firewallRules = ''
      iifname "ens18" tcp dport 9100 counter accept
    '';
    listenAddress = hostIPv4;
  };
  system.stateVersion = "25.05";
}
