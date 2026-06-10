{
  containers.dn42 = {
    privateNetwork = true;
    hostAddress6 = "2600:1702:6630:3fed:100:320:100:100";
    localAddress6 = "2600:1702:6630:3fed:101:321:101:101/128";
    autoStart = true;
    config = {
      system.stateVersion = "26.05";
    };
  };
}
