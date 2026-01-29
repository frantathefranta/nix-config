{ inputs, outputs, ... }:

{
  imports = [
    inputs.srvos.nixosModules.server
    inputs.srvos.nixosModules.hardware-hetzner-cloud
    ../common/global/nix.nix
    ../common/global/sops.nix
    ../common/optional/autoupgrade.nix
    ./dn42
  ]
  ++ (builtins.attrValues outputs.nixosModules);
  networking = {
    hostName = "nix-hetzner";
  };
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
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOQqaMxYeqp/5gsnH7ZH80dq/awufVB0eTq5d4v3tR+S"
  ];

  system.stateVersion = "25.05";
  nixpkgs.hostPlatform = "x86_64-linux";
}
