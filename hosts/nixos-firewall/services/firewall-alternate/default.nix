{
  ipamOf,
  inputs,
  outputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  # Build one firewall zone per host in infra.franta.us using their IPAM data.
  # Self is excluded to avoid infinite recursion during flake evaluation.
  infraHostZones =
    let
      otherHosts = builtins.removeAttrs outputs.nixosConfigurations [ config.networking.hostName ];
      infraHosts = lib.filterAttrs (
        _: hostCfg: hostCfg.config.networking.domain == "infra.franta.us"
      ) otherHosts;
    in
    lib.mapAttrs (
      _: hostCfg:
      let
        host = hostCfg.config.meta.ipam.host;
      in
      lib.filterAttrs (_: v: v != [ ]) {
        ipv4Addresses = lib.optional (host.ipv4 != null) host.ipv4;
        ipv6Addresses = lib.optional (host.resolvedIPv6 != null) host.resolvedIPv6;
      }
    ) infraHosts;
in
{
  imports = [
    inputs.nnf.nixosModules.default
  ];
  networking = {
    firewall.enable = false;
    nat.enable = false;
    nftables.chains.prerouting.nat = {
      after = [ "hook" ];
      rules = [
        "iifname wan0 tcp dport 32400 dnat ip to 10.32.10.210"
        "iifname wan0 udp dport { 40002, 44069 } dnat ip to ${(ipamOf "qotom").ipv4}" # Qotom wireguard to R2s and Mikrotik
        "iifname wan0 tcp dport 18903 dnat ip to 10.33.40.63"
        "iifname wan0 tcp dport 51413 dnat ip to 10.33.40.64"
        "iifname wan0 tcp dport 51414 dnat ip to 10.33.40.65"
      ];
    };
    nftables.firewall = {
      enable = true;
      snippets = {
        nnf-common.enable = true;
        nnf-conntrack.enable = true;
        nnf-default-stopRuleset.enable = true;
        nnf-drop.enable = true;
        nnf-loopback.enable = true;
        nnf-dhcpv6.enable = true;
        nnf-icmp = {
          enable = true;
          ipv6Types = [
            "echo-request"
            "nd-router-solicit" # The default snippet is missing this
            "nd-router-advert"
            "nd-neighbor-solicit"
            "nd-neighbor-advert"
          ];
        };
        nnf-ssh.enable = true;
        nnf-nixos-firewall.enable = false;
      };
      zones = infraHostZones // {
        untrusted = {
          interfaces = [ "wan0" ];
        };
        mgmt = {
          interfaces = [
            "eth6"
            "mgmt"
          ];
        };
        local_interfaces = {
          interfaces = [
            "lan0"
            "lan0.20"
            "lan0.50"
          ];
        };
        guest = {
          interfaces = [
            "lan0.999"
          ];
        };
        wg = {
          interfaces = [ "wg_iphone" ];
        };
        wifi = {
          interfaces = [
            "lan0.20"
          ];
        };
        iot = {
          interfaces = [
            "lan0.50"
          ];
        };
        lab_space = {
          ipv4Addresses = [
            "10.0.0.0/24"
            "10.32.10.0/24"
            "10.33.0.0/16"
            "10.40.0.0/16"
          ];
          ipv6Addresses = [
            "2600:1702:6630:3fec::/62"
            "2600:1702:6630:3fea::/64"
          ];
        };
        plex = {
          ipv4Addresses = [ "10.32.10.210/32" ];
          ipv6Addresses = [ "2600:1702:6630:3fed:ba85:84ff:feb9:446e/128" ];
        };
        qbittorrent = {
          ipv4Addresses = [ "10.33.40.63" ];
          ipv6Addresses = [ "2600:1702:6630:3fef:4040:2:0:63" ];
        };
        transmission_jeopardy = {
          ipv4Addresses = [ "10.33.40.64" ];
          ipv6Addresses = [ "2600:1702:6630:3fef:4040:2:0:64" ];
        };
        transmission_music = {
          ipv4Addresses = [ "10.33.40.65" ];
          ipv6Addresses = [ "2600:1702:6630:3fef:4040:2:0:65" ];
        };
        envoy_external = {
          ipv6Addresses = [ "2600:1702:6630:3fef:4040:2:0:14" ];
        };
        hass = {
          ipv4Addresses = [
            "10.0.50.30"
          ];
        };
      };
      rules = {
        wan_egress = {
          from = [
            "local_interfaces"
            "guest"
            "wg"
          ];
          to = [ "untrusted" ];
          verdict = "accept";
          late = true;
          masquerade = true;
        };
        allow_hass_everywhere = {
          from = [ "hass" ];
          to = [ "local_interfaces" ];
          verdict = "accept";
        };
        allow_wifi_to_iot = {
          from = [ "wifi" ];
          to = [ "iot" ];
          verdict = "accept";
        };
        allow_iot_to_wifi_mdns = {
          from = [ "iot" ];
          to = [ "wifi" ];
          verdict = "accept";
        };
        allow_access_to_lab = {
          from = [
            "local_interfaces"
            "wg"
          ];
          to = [ "lab_space" ];
          verdict = "accept";
        };
        allow_access_from_lab = {
          from = [ "lab_space" ];
          to = [ "local_interfaces" ];
          verdict = "accept";
        };
        allow_dns = {
          from = [
            "local_interfaces"
            "wg"
          ];
          allowedUDPPorts = [ 53 ];
          to = [ "fw" ];
        };
        allow_dns_mgmt = {
          from = [ "mgmt" ];
          allowedTCPPorts = [ 8853 ];
          to = [ "fw" ];
        };
        allow_prometheus_node_exporter = {
          from = [ "lab_space" ];
          allowedTCPPorts = [ 9100 ];
          to = [ "fw" ];
        };
        allow_dns_api = {
          from = [
            "lab_space"
            "local_interfaces"
            "wg"
          ];
          to = [ "fw" ];
          allowedTCPPorts = [ 8081 ];
        };
        allow_multicast_to_fw = {
          from = [
            "wifi"
            "iot"
          ];
          allowedUDPPorts = [
            1900
            5353
          ];
          to = [ "fw" ];
        };
        allow_ntp = {
          from = [
            "local_interfaces"
            "lab_space"
          ];
          allowedUDPPorts = [ 123 ];
          to = [ "fw" ];
        };
        allow_znc = {
          from = [
            "untrusted"
            "wifi"
            "wg"
          ];
          to = [ "fw" ];
          allowedTCPPorts = [ config.services.znc.config.Listener.l.Port ];
        };
        allow_wg_from_wan = {
          from = [ "untrusted" ];
          to = [ "fw" ];
          allowedUDPPorts = [ config.systemd.network.netdevs."50-wg_iphone".wireguardConfig.ListenPort ];
        };
        allow_wg_to_local = {
          from = [ "wg" ];
          to = [ "local_interfaces" ];
          verdict = "accept";
        };
        allow_plex = {
          from = [ "untrusted" ];
          to = [ "plex" ];
          allowedTCPPorts = [ 32400 ];
        };
        allow_qbittorrent = {
          from = [ "untrusted" ];
          to = [ "qbittorrent" ];
          allowedTCPPorts = [ 18903 ];
        };
        allow_transmission_jeopardy = {
          from = [ "untrusted" ];
          to = [ "transmission_jeopardy" ];
          allowedTCPPorts = [ 51413 ];
        };
        allow_transmission_music = {
          from = [ "untrusted" ];
          to = [ "transmission_music" ];
          allowedTCPPorts = [ 51414 ];
        };
        allow_envoy_external = {
          from = [ "untrusted" ];
          to = [ "envoy_external" ];
          allowedTCPPorts = [
            22
            80
            443
          ];
        };
        allow_qotom_wg = {
          from = [ "untrusted" ];
          to = [ "qotom" ];
          allowedUDPPorts = [
            40002
            44069
          ];
        };
        allow_bgp_from_lab = {
          from = [ "lab_space" ];
          to = [ "fw" ];
          allowedTCPPorts = [
            179
          ];
        };
        allow_http_and_https = {
          from = [ "untrusted" ];
          to = [ "hydrogen" ];
          allowedTCPPorts = [
            80
            443
          ];
        };
        allow_wg_mikrotik = {
          from = [ "untrusted" ];
          to = [ "fw" ];
          allowedUDPPorts = [
            41000
          ];
        };
        allow_molybdenum_dn42 = {
          from = [ "untrusted" ];
          to = [ "molybdenum" ];
          allowedUDPPortRanges = [
            {
              from = 20000;
              to = 30000;
            }
          ];
          allowedTCPPorts = [ 9000 ];
        };
      };
    };
  };
}
