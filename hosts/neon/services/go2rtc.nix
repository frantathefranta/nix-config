{ config, ... }:
{
  virtualisation.quadlet.containers.podman-go2rtc = {
    autoStart = false; # Started by the pod.
    unitConfig = {
      After = [ "go2rtc.service" ];
      Conflicts = [ "go2rtc.service" ];
    };
    containerConfig = {
      name = "go2rtc";
      pod = config.virtualisation.quadlet.pods.home-assistant.ref;
      image = "ghcr.io/alexxit/go2rtc:1.9.15";
      environmentFiles = [ config.sops.secrets."go2rtc/env".path ];
      volumes = [ "go2rtc:/config" ];
    };
  };

  sops.secrets."go2rtc/env" = {
    sopsFile = ../secrets.yaml;
    restartUnits = [ "podman-go2rtc.service" ];
  };
}
