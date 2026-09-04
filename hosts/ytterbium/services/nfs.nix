{ config, ... }:
{
  boot.supportedFilesystems.nfs = true;
  services.nfs.server = {
    enable = true;
    exports = {
      "/emc1/scrypted" = {
        "2600:1702:6630:3fe0::/60" = [
          "sec=sys"
          "rw"
          "no_subtree_check"
          "mountpoint"
        ];
      };
      "/emc1/media" = {
        "2600:1702:6630:3fe0::/60" = [
          "sec=sys"
          "rw"
          "no_subtree_check"
          "mountpoint"
        ];
      };
      "/emc1/music" = {
        "2600:1702:6630:3fe0::/60" = [
          "sec=sys"
          "rw"
          "no_subtree_check"
          "mountpoint"
        ];
      };
      "/emc1/jeopardy" = {
        "2600:1702:6630:3fe0::/60" = [
          "sec=sys"
          "rw"
          "no_subtree_check"
          "mountpoint"
        ];
      };
    };
  };
  networking.firewall = {
    allowedTCPPorts = [
      111
      2049
      4000
      4001
      4002
      20048
    ];
    allowedUDPPorts = [
      111
      2049
      4000
      4001
      4002
      20048
    ];
  };
  networking.domains.subDomains = {
    "nfs.${config.networking.domain}".cname.data = "${config.networking.hostName}-40g";
  };
}
