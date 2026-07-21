{ config, pkgs, ... }:
let
  peerfinder-script = pkgs.stdenv.mkDerivation {
    name = "peerfinder-script";
    propagatedBuildInputs = [ pkgs.python3 ];
    dontUnpack = true;
    installPhase = "install -Dm755 ${./peerfinder-agent.py} $out/bin/peerfinder-script";
  };
in
{
  systemd.services."peerfinder-agent" = {
    description = "DN42 Peer Finder Measurement Agent";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.iputils ];
    serviceConfig = {
      ExecStart = "${peerfinder-script}/bin/peerfinder-script";
      Type = "simple";
      Restart = "always";
      RestartSec = "300s";
      DynamicUser = "yes";
      SupplementaryGroups = [ "peerfinder" ];
      ProtectSystem = "strict";
      NoNewPrivileges = "yes";
      RestrictAddressFamilies = "AF_INET AF_INET6";
      AmbientCapabilities = "CAP_NET_RAW";
      CapabilityBoundingSet = "CAP_NET_RAW";
      SystemCallArchitectures = "native";
      MemoryDenyWriteExecute = "true";
      TasksMax = "20";
    };
    environment = {
      SECRET_KEY_FILE = config.sops.secrets.peerfinder.path;
    };
  };

  users.groups.peerfinder = { };

  sops.secrets.peerfinder = {
    sopsFile = ../../${config.networking.hostName}/secrets.yaml;
    group = "peerfinder";
    mode = "0440";
  };
  networking.nftables.firewall.rules.allow_peerfinder = {
    from = [
      "untrusted"
    ];
    to = [ "fw" ];
    allowedTCPPorts = [ 9000 ];
  };
}
