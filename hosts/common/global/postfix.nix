{
  services.postfix = {
    enable = true;
    settings.main = {
      relayhost = [ "smtp-relay.franta.us:25" ];
      myorigin = "$mydomain";
      mydomain = "franta.dev";
    };
  };
}
