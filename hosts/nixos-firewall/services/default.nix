{
  imports = [
    ./network.nix
    ./lldpd.nix
    # ./firewall
    ./firewall-alternate
    ./powerdns.nix
    ./dhcp.nix
    ./udpbroadcastrelay.nix
    # TODO: ./radvd.nix
    # TODO: ./ntp.nix
    # TODO: ./routing.nix
    # TODO: ./qos.nix # https://github.com/budimanjojo/nix-config/blob/main/system/hosts/budimanjojo-firewall/_modules/services/fireqos/default.nix
  ];
}
