{ inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common/global
    ../common/roles/server.nix
  ];

  networking = {
    hostName = "nix-oci";
    domain = "us.franta.us";
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
      "2606:4700:4700::1111"
      "2606:4700:4700::1001"
    ];
  };
  systemd.network.enable = true;
  systemd.network.networks."10-wan" = {
    matchConfig.Name = "enp0s6";
      # Only "required" for IPv6
    networkConfig.DHCP = "ipv6";
    address = [
      "10.0.0.98/24"
    ];
    routes = [
      { Gateway = "10.0.0.1"; }
    ];
  };
  time.timeZone = "America/Chicago";

  # Keep root SSH access for emergency recovery
  services.openssh.settings.PermitRootLogin = "prohibit-password";
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHXiHtQnI5YhZX9eVBdwHJlWm+5O08rCUtyWKTqq9zLM"
  ];

  system.stateVersion = "25.11";
  nixpkgs.hostPlatform = "aarch64-linux";
}
