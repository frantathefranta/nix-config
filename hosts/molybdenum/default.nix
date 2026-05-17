{ inputs, ... }:
let
  hostIPv4 = "10.32.10.242";
in
{
  imports = [
    #./services
    inputs.nixos-dns.nixosModules.dns
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
    domains = {
      enable = true;
      defaultTTL = 86400;
      baseDomains."franta.dn42" = { };
      subDomains."ns0.franta.dn42" = {
        a.data = "172.23.234.30";
        aaaa.data = "fdb7:c21f:f30f:53::";
      };
      subDomains."us-cmh.franta.dn42" = {
        a.data = "172.23.234.17";
        aaaa.data = "fdb7:c21f:f30f::1";
      };
      subDomains."us-cmh-wg-home.franta.dn42" = {
        aaaa.data = "fdb7:c21f:f30f:98::1";
      };
      subDomains."lg.franta.dn42" = {
        cname.data = "us-cmh";
      };
    };
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
      "2606:4700:4700::1111"
      "2606:4700:4700::1001"
    ];
  };
  systemd.network = {
    enable = true;
  };
  systemd.network.networks."10-wan" = {
    matchConfig.Name = "ens18";
    networkConfig = {
      IPv6PrivacyExtensions = false;
    };
    address = [
      "${hostIPv4}/24"
      "2600:1702:6630:3fed::242/64"
    ];
    routes = [
      { Gateway = "10.32.10.254"; }
      { Gateway = "fe80::464c:a8ff:fede:3cf7"; }
    ];
    vlan = [ "ens18.2000" ];
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
