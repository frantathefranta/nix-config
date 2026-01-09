{ lib, config, ... }:
{
  services.postfix = lib.mkIf (config.networking.domain == "infra.franta.us") {
    enable = true;
    settings.main = {
      relayhost = [ "smtp-relay.franta.us:25" ];
      myorigin = "$mydomain";
      mydomain = "franta.dev";
    };
  };
}
