{ inputs, outputs, ... }:

{
  imports = [
    inputs.srvos.nixosModules.hardware-hetzner-cloud
    ../common/global/nix.nix
    ../common/global/sops.nix
    ../common/roles/server.nix
    ../common/optional/autoupgrade.nix
    ./dn42
  ]
  ++ (builtins.attrValues outputs.nixosModules);
  networking = {
    hostName = "nix-hetzner";
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
  # TODO: This needs to be handled by roles/server.nix
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHXiHtQnI5YhZX9eVBdwHJlWm+5O08rCUtyWKTqq9zLM"
  ];

  system.stateVersion = "25.05";
  nixpkgs.hostPlatform = "x86_64-linux";
}
