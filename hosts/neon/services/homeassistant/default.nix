{ config, pkgs, ... }:
{
  imports = [
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

  environment.etc."containers/networks/ha-vlan20.json".source =
    (pkgs.formats.json { }).generate "ha-vlan20.json" {
      name = "ha-vlan20";
      id = builtins.hashString "sha256" "ha-vlan20";
      driver = "macvlan";
      network_interface = "eno3.20";
      ipv6_enabled = true;
      dns_enabled = false;
      ipam_options.driver = "host-local";
      subnets = [
        {
          subnet = "10.0.20.0/24";
          gateway = "10.0.20.1";
        }
        {
          subnet = "2600:1702:6630:3fe1::/64";
          gateway = "2600:1702:6630:3fe1:10:0:20:1";
        }
      ];
    };

  virtualisation.oci-containers = {
    backend = "podman";
    containers.home-assistant = {
      image = "ghcr.io/home-assistant/home-assistant:2026.11.1";
      environment.TZ = config.time.timeZone;
      volumes = [
        "home-assistant:/config"
        "/run/postgresql:/run/postgresql:ro"
      ];
      networks = [ "ha-vlan20:ip=10.0.20.30,ip6=2600:1702:6630:3fe1:10:0:20:30" ];
      extraOptions = [
        "--dns=10.0.20.1"
        # Learn Thread border-router routes in the shared network namespace.
        "--sysctl=net.ipv6.conf.all.forwarding=0"
        "--sysctl=net.ipv6.conf.eth0.accept_ra=1"
        "--sysctl=net.ipv6.conf.eth0.accept_ra_defrtr=0"
        "--sysctl=net.ipv6.conf.eth0.accept_ra_rt_info_max_plen=64"
      ];
    };
  };

  systemd.services.podman-home-assistant = {
    after = [
      "sys-subsystem-net-devices-eno3.20.device"
      "postgresql.target"
    ];
    requires = [ "postgresql.target" ];
    upholds = [
      "podman-caddy.service"
      "podman-matter-server.service"
    ];
    # Restart with PostgreSQL so Podman remounts its recreated runtime directory.
    partOf = [ "postgresql.target" ];
    bindsTo = [ "sys-subsystem-net-devices-eno3.20.device" ];
    restartTriggers = [ config.environment.etc."containers/networks/ha-vlan20.json".source ];
  };
}
