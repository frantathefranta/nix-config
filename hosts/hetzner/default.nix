{ inputs, ... }:

{
  imports = [
    inputs.srvos.nixosModules.server
    inputs.srvos.nixosModules.hardware-hetzner-cloud
  ];
  networking = {
    hostName = "nixos-hetzner";
  };
  systemd.network.enable = true;
  systemd.network.networks."10-wan" = {
    matchConfig.Name = "eth0"; 
    networkConfig.DHCP = "ipv4";
    address = [
      "2a01:4ff:1f0:d924::1/64"
    ];
    routes = [
      { routeConfig.Gateway = "fe80::1"; }
    ];
  };

  system.stateVersion = "25.05";
  nixpkgs.hostPlatform = "x86_64-linux";
}
