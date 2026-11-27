{ config, ... }:
{
  virtualisation.quadlet.containers.podman-matter-server = {
    autoStart = false; # Started by the pod.
    containerConfig = {
      name = "matter-server";
      pod = config.virtualisation.quadlet.pods.home-assistant.ref;
      image = "ghcr.io/matter-js/matterjs-server:1.5.5";
      environments = {
        LISTEN_ADDRESS = "127.0.0.1";
        PRIMARY_INTERFACE = "eth0";
      };
      volumes = [ "matter-server:/data" ];
    };
  };
}
