{ inputs, lib, config, ... }:

{
  imports = [
    inputs.srvos.nixosModules.hardware-hetzner-cloud
    ../common/global
    ../common/roles/server.nix
    ../common/users/fbartik
    ../common/optional/autoupgrade.nix
    ./dn42
  ];
  networking = {
    hostName = "nix-hetzner";
    domain = "us.franta.us";
    nameservers = [ ];
  };
  time.timeZone = "America/Seattle";
  systemd.network.enable = true;
  systemd.network.networks."10-wan" = {
    matchConfig.Name = "eth0";
    networkConfig.DHCP = "ipv4";
    dhcpV4Config.UseDNS = false;
    ipv6AcceptRAConfig.UseDNS = false;
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

  system.stateVersion = "25.05";
  nixpkgs.hostPlatform = "x86_64-linux";
}
