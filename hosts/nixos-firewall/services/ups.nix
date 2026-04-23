{ config,  ... }:

{
  power.ups = {
    enable = true;
    mode = "netserver";
    upsmon.monitor."apc-rack-pdu01" = {
      system = "apc-rack-pdu01.infra.franta.us";
      user = "apc";
      powerValue = 1; # Number of power supplies that the UPS feeds on this system
      passwordFile = config.sops.secrets."ups/apcPassword".path;
    };
  };
  sops.secrets."ups/apcPassword" = {
    sopsFile = ../secrets.yaml;
  };
}
