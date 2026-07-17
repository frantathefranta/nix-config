{ pkgs, outputs, ... }:
{
  imports = [
    ./dns.nix
    ./interfaces.nix
    ./firewall.nix
    ./bird
    ./stayrtr.nix
    ./ping-exporter.nix
    ../../../modules/nixos/dn42-ipam.nix
  ];

  meta.dn42.ipv6Prefix48 = "fdb7:c21f:f30f";

  _module.args.dn42Of = hostname: outputs.nixosConfigurations.${hostname}.config.meta.dn42.host;
  
  deployment.tags = [ "dn42" ];

  environment.systemPackages = [ pkgs.wireguard-tools ];
  
  systemd.network.config.networkConfig = {
    IPv4Forwarding = true;

    # This will break IPv6 RA if IPv6AcceptRA is not explicitly set
    IPv6Forwarding = true;
  };

  boot.kernel.sysctl = {
    "net.ipv4.conf.all.rp_filter" = 0;
    "net.ipv4.conf.default.rp_filter" = 0;
  };
}
