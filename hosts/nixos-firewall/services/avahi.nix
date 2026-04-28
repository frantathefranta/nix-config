{
  services.avahi = {
    enable = true;
    allowInterfaces = [ "lan0.20" "lan0.50" ];
    reflector = true;
    openFirewall = false;
  };
}
