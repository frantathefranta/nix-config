{ config, pkgs, ... }:
{
  virtualisation.quadlet.containers.podman-mosquitto = {
    autoStart = false; # Started by the pod.
    containerConfig = {
      name = "mosquitto";
      pod = config.virtualisation.quadlet.pods.home-assistant.ref;
      image = "docker.io/library/eclipse-mosquitto:2.1.4-alpine";
      volumes = [
        "mosquitto:/mosquitto/data"
        "${pkgs.writeText "mosquitto.conf" ''
          listener 1883
          allow_anonymous true
          persistence true
          persistence_location /mosquitto/data/
          autosave_interval 60
          log_dest stdout
        ''}:/mosquitto/config/mosquitto.conf:ro"
      ];
    };
  };
}
