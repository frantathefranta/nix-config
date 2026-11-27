{ config, inputs, ... }:
{
  imports = [
    inputs.quadlet-nix.nixosModules.quadlet
    ./service.nix

    ./matter.nix
    ./mosquitto.nix
    ./postgres.nix
    ./proxy.nix
  ];

  services.postgresql = {
    ensureDatabases = [ "homeassistant" ];
    ensureUsers = [
      {
        name = "homeassistant";
        ensureDBOwnership = true;
      }
    ];
    # The rootful container connects over the local socket as host UID 0.
    authentication = "local homeassistant homeassistant peer map=homeassistant";
    identMap = "homeassistant root homeassistant";
  };

  virtualisation.quadlet = {
    networks.ha-vlan20 = {
      autoStart = false;
      unitConfig = {
        After = [ "sys-subsystem-net-devices-eno3.20.device" ];
        BindsTo = [ "sys-subsystem-net-devices-eno3.20.device" ];
      };
      networkConfig = {
        driver = "macvlan";
        interfaceName = "eno3.20";
        disableDns = true;
        ipv6 = true;
        subnets = [
          "10.0.20.0/24"
          "2600:1702:6630:3fe1::/64"
        ];
        gateways = [
          "10.0.20.1"
          "2600:1702:6630:3fe1:10:0:20:1"
        ];
      };
    };

    pods.home-assistant = {
      unitConfig.BindsTo = [ "ha-vlan20-network.service" ];
      unitConfig.PartOf = [ "ha-vlan20-network.service" ];
      podConfig = {
        networks = [ config.virtualisation.quadlet.networks.ha-vlan20.ref ];
        ip = "10.0.20.30";
        ip6 = "2600:1702:6630:3fe1:10:0:20:30";
        dns = [ "10.0.20.1" ];
        # Learn Thread border-router routes in the pod's network namespace.
        podmanArgs = [
          "--sysctl=net.ipv6.conf.all.forwarding=0"
          "--sysctl=net.ipv6.conf.eth0.accept_ra=1"
          "--sysctl=net.ipv6.conf.eth0.accept_ra_defrtr=0"
          "--sysctl=net.ipv6.conf.eth0.accept_ra_rt_info_max_plen=64"
        ];
      };
    };

    containers.podman-home-assistant = {
      autoStart = false; # Started by the pod.
      unitConfig = {
        After = [ "postgresql.target" ];
        Requires = [ "postgresql.target" ];
        # Remount the socket directory whenever PostgreSQL recreates it.
        PartOf = [ "postgresql.target" ];
      };
      containerConfig = {
        name = "home-assistant";
        pod = config.virtualisation.quadlet.pods.home-assistant.ref;
        image = "ghcr.io/home-assistant/home-assistant:2026.11.1";
        environments.TZ = config.time.timeZone;
        volumes = [
          "home-assistant:/config"
          "/run/postgresql:/run/postgresql:ro"
        ];
      };
    };
  };
}
