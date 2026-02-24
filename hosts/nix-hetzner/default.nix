{ inputs, ... }:

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
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
      "2606:4700:4700::1111"
      "2606:4700:4700::1001"
    ];
  };
  time.timeZone = "America/Seattle";
  systemd.network.enable = true;
  systemd.network.networks."10-wan" = {
    matchConfig.Name = "eth0";
    networkConfig.DHCP = "ipv4";
    address = [
      "2a01:4ff:1f0:d924::1/64"
    ];
    routes = [
      { Gateway = "fe80::1"; }
    ];
  };

  # Keep root SSH access for emergency recovery
  services.openssh.settings.PermitRootLogin = "prohibit-password";
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHXiHtQnI5YhZX9eVBdwHJlWm+5O08rCUtyWKTqq9zLM"
  ];

  system.stateVersion = "25.05";
  nixpkgs.hostPlatform = "x86_64-linux";
}
