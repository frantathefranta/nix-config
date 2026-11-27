{
  virtualisation.oci-containers.containers.matter-server = {
    image = "ghcr.io/matter-js/matterjs-server:1.5.5";
    autoStart = false; # Started and kept running by podman-home-assistant.
    networks = [ "container:home-assistant" ];
    environment = {
      LISTEN_ADDRESS = "127.0.0.1";
      PRIMARY_INTERFACE = "eth0";
    };
    volumes = [ "matter-server:/data" ];
  };

  # The network namespace is recreated whenever the HA container is replaced.
  systemd.services.podman-matter-server = {
    after = [ "podman-home-assistant.service" ];
    bindsTo = [ "podman-home-assistant.service" ];
    partOf = [ "podman-home-assistant.service" ];
  };
}
