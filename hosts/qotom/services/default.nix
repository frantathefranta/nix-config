{
  imports = [
    ./hostapd.nix
  ];
  services = {
    lldpd.enable = true;
    atftpd.enable = true;
  };
}
