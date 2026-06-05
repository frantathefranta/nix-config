{
  config,
  inputs,
  lib,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../common/global
    ../common/roles/server.nix

    ./services
  ];

  networking = {
    hostName = "nix-oci";
    domain = "cloud.franta.us";
    domains.subDomains."${config.networking.hostName}.${config.networking.domain}" = {
      aaaa.data = [ "2603:c028:4507:4100:0:d10f:fabd:239c" ];
    };
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
      "2606:4700:4700::1111"
      "2606:4700:4700::1001"
    ];
    nftables.enable = true;
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

  services.prometheus.exporters.node.openFirewall = false;
  system.stateVersion = "25.11";
  nixpkgs.hostPlatform = "aarch64-linux";
}
