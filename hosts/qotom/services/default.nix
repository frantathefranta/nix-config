{
  imports = [
    ./hostapd.nix
    ./syslog.nix
    ./conman.nix
    ./caddy.nix
  ];
  services = {
    lldpd.enable = true;
    atftpd.enable = true;
  };
  networking.firewall.interfaces.enp1s0.allowedUDPPorts = [
    69 # TFTP
    514 # Syslog
  ];
}
