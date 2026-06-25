{ pkgs, ... }:
{
  imports = [
    ./dns.nix
    ./interfaces.nix
    ./firewall.nix
    ./stayrtr.nix
    ../../../modules/nixos/dn42-ipam.nix
  ];

  meta.dn42.ipv6Prefix48 = "fdb7:c21f:f30f";

  environment.systemPackages = [ pkgs.wireguard-tools ];
  
  systemd.network.config.networkConfig = {
    IPv4Forwarding = true;
    IPv6Forwarding = true;
  };
}
