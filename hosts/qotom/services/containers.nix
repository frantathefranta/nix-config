{
  systemd.network = {
    netdevs."20-br_dn42" = {
      netdevConfig = {
        Name = "br_dn42";
        Kind = "bridge";
      };
    };
    networks."20-br_dn42" = {
      matchConfig.Name = "br_dn42";
      address = [
        "2600:1702:6630:3fed:1032:1010::1/96"
      ];
      # linkConfig.RequiredForOnline = false;
    };
  };
  containers.dn42 = {
    privateNetwork = true;
    hostBridge = "br_dn42";
    # hostAddress6 = "2600:1702:6630:3fed:100:320:100:100";
    localAddress6 = "2600:1702:6630:3fed:1032:1010::2/96";
    autoStart = true;
    config = {
      system.stateVersion = "26.05";
      services.resolved.enable = true;
      networking.useHostResolvConf = false;
      # networking.defaultGateway6 = {
      #   address = "fe80::5861:c3ff:fe63:37d4";
      #   interface = "eth0";
      # };
    };
  };
}
