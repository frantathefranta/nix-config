let
  net = import ./container-addresses.nix;
in
{
  # Upstream routers, including nixos-firewall, must route/permit both aggregates.
  # IPv4 Internet egress needs perimeter NAT; no masquerading is done here.
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  # Keep the host's existing static/RA default routes. Explicit IPv6AcceptRA
  # remains enabled in the host's systemd-networkd configuration when routing.
  systemd.network.networks."10-ens18".address = [ "${net.localLinkLocal}/64" ];

  services.bird = {
    enable = true;
    # The NixOS module validates this configuration with bird -p at build time.
    config = ''
      router id ${net.routerId};
      log stderr all;

      protocol device {}

      # Only aggregates enter BIRD. Container peer routes stay kernel-managed.
      # Aggregates remain advertised even when the containers are stopped.
      protocol static container_prefixes4 {
        ipv4;
        route ${net.ipv4Prefix} blackhole;
      }
      protocol static container_prefixes6 {
        ipv6;
        route ${net.ipv6Prefix} blackhole;
      }

      # Discard unused destinations; live /32 and /128 container routes win.
      # Do not import host defaults or redistribute unrelated kernel routes.
      protocol kernel container_kernel4 {
        ipv4 {
          import none;
          export filter {
            if proto = "container_prefixes4" && net = ${net.ipv4Prefix} then accept;
            reject;
          };
        };
      }
      protocol kernel container_kernel6 {
        ipv6 {
          import none;
          export filter {
            if proto = "container_prefixes6" && net = ${net.ipv6Prefix} then accept;
            reject;
          };
        };
      }

      protocol bgp arista {
        local ${net.localLinkLocal} as ${toString net.localAS};
        neighbor ${net.peerLinkLocal}%${net.uplink} as ${toString net.peerAS};
        strict bind on;
        # Initiate toward Arista; stateful host filtering permits the replies.
        passive off;
        ipv4 {
          extended next hop on;
          next hop self;
          import none;
          export filter {
            if proto = "container_prefixes4" && net = ${net.ipv4Prefix} then accept;
            reject;
          };
        };
        ipv6 {
          next hop self;
          import none;
          export filter {
            if proto = "container_prefixes6" && net = ${net.ipv6Prefix} then accept;
            reject;
          };
        };
      }
    '';
  };

  systemd.services.bird = {
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
  };
}
