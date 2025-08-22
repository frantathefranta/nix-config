{
  services.postfix = {
    enable = true;
    relayHost = "smtp-relay.franta.us";
    relayPort = 25;
    origin = "$mydomain";
    domain = "franta.dev";
  };
}
