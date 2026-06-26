{ pkgs, ... }:
{
  systemd.services.stayrtr = {
    description = "StayRTR";
    after = [ "network.target" ];
    wantedBy = [
      "multi-user.target"
      "bird.service"
    ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.stayrtr}/bin/stayrtr -cache=https://dn42.burble.com/roa/dn42_roa_46.json -bind [::1]:8282 -metrics.addr [::1]:9847";
    };
  };
}
