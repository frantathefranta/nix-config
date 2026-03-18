{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.wireguard-tools ];
  systemd.services.stayrtr = {
    description = "StayRTR";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.stayrtr}/bin/stayrtr -cache=https://dn42.burble.com/roa/dn42_roa_46.json";
    };
  };
  # TODO: Move common BIRD configuration here
}
