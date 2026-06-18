{
  inputs,
  lib,
  config,
  ...
}:

{
  imports = [
    inputs.srvos.nixosModules.hardware-hetzner-cloud
    ../common/global
    ../common/roles/server.nix
    ../common/users/fbartik
    ../common/optional/autoupgrade.nix
    ../common/dn42
    ./dn42
  ];
  networking = {
    hostName = "nix-hetzner";
    domain = "cloud.franta.us";
    domains.subDomains."${config.networking.hostName}.${config.networking.domain}" = {
      aaaa.data = [ "2a01:4ff:1f0:d924::1" ];
    };
    nameservers = [
      "2a01:4ff:ff00::add:1"
      "2a01:4ff:ff00::add:2"
    ];
  };
  time.timeZone = "America/Seattle";
  systemd.network.enable = true;
  systemd.network.networks."05-wan" = {
    matchConfig.Name = "eth0";
    networkConfig.DHCP = "ipv4";
    dhcpV4Config.UseDNS = false;
    dns = config.networking.nameservers;
    address = [
      "2a01:4ff:1f0:d924::1/64"
    ];
    routes = [
      { Gateway = "fe80::1"; }
    ];
  };
  # services.resolved = lib.mkDefault { fallbackDns = config.networking.nameservers; };

  # Keep root SSH access for emergency recovery
  services.openssh.settings.PermitRootLogin = "prohibit-password";
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHXiHtQnI5YhZX9eVBdwHJlWm+5O08rCUtyWKTqq9zLM"
  ];

  meta.ipam.host = {
    ipv6 = "2a01:4ff:1f0:d924::1";
  };
  system.stateVersion = "25.05";
  nixpkgs.hostPlatform = "x86_64-linux";
}
