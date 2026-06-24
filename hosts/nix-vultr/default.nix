{
  config,
  inputs,
  ...
}:

{
  imports = [
    inputs.srvos.nixosModules.hardware-vultr-vm
    ./hardware-configuration.nix
    ../common/global
    ../common/roles/server.nix

    # ./services
  ];
  hardware.facter.reportPath = ./facter.json;

  networking = {
    hostName = "nix-vultr";
    domain = "cloud.franta.us";
    domains.subDomains."${config.networking.hostName}.${config.networking.domain}" = {
      aaaa.data = [ config.meta.ipam.host.ipv6 ];
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
    matchConfig.Name = "enp1s0";
    # Only "required" for IPv6
    networkConfig.DHCP = true;
  };
  time.timeZone = "Europe/Warsaw";

  # Keep root SSH access for emergency recovery
  services.openssh.settings.PermitRootLogin = "prohibit-password";
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHXiHtQnI5YhZX9eVBdwHJlWm+5O08rCUtyWKTqq9zLM"
  ];

  meta.ipam.host = {
    ipv4 = "64.176.75.13";
    ipv6 = "2a05:f480:2400:29f9:5400:6ff:fe4a:c09d";
  };
  services.prometheus.exporters.node.openFirewall = false;
  system.stateVersion = "25.11";
  nixpkgs.hostPlatform = "x86_64-linux";
}
