{
  imports = [
    ./network.nix
    ./ntp.nix
    ./lldpd.nix
    # ./firewall
    ./firewall-alternate
    ./powerdns.nix
    ./dhcp.nix
    ./udpbroadcastrelay.nix
    ./avahi.nix
    ./routing.nix
    # TODO: ./qos.nix # https://github.com/budimanjojo/nix-config/blob/main/system/hosts/budimanjojo-firewall/_modules/services/fireqos/default.nix
    ./znc.nix
    ./ups.nix
    ./fail2ban.nix
    ./rust-motd.nix
    ./syslog.nix
    ./oxidized.nix
  ];
}
