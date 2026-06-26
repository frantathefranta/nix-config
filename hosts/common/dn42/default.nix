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

    # This will break IPv6 RA if IPv6AcceptRA is not explicitly set
    IPv6Forwarding = true;
  };
}
