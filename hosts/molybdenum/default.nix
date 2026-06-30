{ config, inputs, ... }:
let
  hostIPv4 = "10.32.10.242";
in
{
  imports = [
    #./services
    ./dn42
    ./hardware-configuration.nix

    ../common/global
    ../common/dn42
    ../common/roles/server.nix
    # ../common/optional/dn42.nix
    ../common/optional/qemu-guest-agent.nix
    ../common/optional/autoupgrade.nix
    ../common/users/fbartik
  ];
  networking = {
    hostName = "molybdenum";
    domains = {
      defaultTTL = 86400;
      subDomains."ns0.franta.dn42" = {
        a.data = "172.23.234.30";
        aaaa.data = "fdb7:c21f:f30f:53::";
      };
      subDomains."us-cmh.franta.dn42" = {
        a.data = config.meta.dn42.host.ipv4;
        aaaa.data = config.meta.dn42.host.resolvedIPv6;
      };
      subDomains."us-cmh-wg-home.franta.dn42" = {
        aaaa.data = "fdb7:c21f:f30f:98::1";
      };
      subDomains."lg.franta.dn42" = {
        cname.data = "us-cmh";
      };
      subDomains."${config.networking.hostName}.${config.networking.domain}" = {
        a.data = hostIPv4;
        aaaa.data = "2600:1702:6630:3fed::242";
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
  systemd.network.networks."05-wan" = {
    matchConfig.Name = "ens18";
    networkConfig = {
      IPv6PrivacyExtensions = false;
    };
    address = [
      "${hostIPv4}/24"
    ];
    ipv6AcceptRAConfig.Token = "::242";
    routes = [
      { Gateway = "10.32.10.254"; }
    ];
    dns = [ "10.0.10.1" ];
    vlan = [ "ens18.2000" ];
  };
  
  meta.ipam.host = {
    ipv4 = hostIPv4;
    ipv6 = "2600:1702:6630:3fed::242";
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
