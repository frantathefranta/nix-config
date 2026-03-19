{
  imports = [
    ./network.nix
    ./lldpd.nix
    ./firewall
    ./powerdns.nix
    ./dhcp.nix
    # ./radvd.nix # Actually this might be possible to handle using systemd-network https://sebastianmeisel.github.io/Ostseepinguin/IPv6PrefixDelegation.html
    # TODO: ./ntp.nix
    # TODO: ./routing.nix
    # TODO: ./qos.nix # https://github.com/budimanjojo/nix-config/blob/main/system/hosts/budimanjojo-firewall/_modules/services/fireqos/default.nix
  ];
}
