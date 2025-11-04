{
  config,
  pkgs,
  lib,
  ...
}:
let
  defaultLocalIPv4 = "172.23.234.17/32";
  defaultLocalIPv6 = "fe80::1723:234/64";
in
{
  environment.systemPackages = [ pkgs.wireguard-tools ];
  networking.wireguard.interfaces = {
    wg4242420207 = {
      listenPort = 20207;
      privateKeyFile = config.sops.secrets."wireguard/routed-bits-private-key".path;
      allowedIPsAsRoutes = false;
      peers = [
          {
            publicKey = "89xUzROs3l/KNPLxDTJz4l5aEH1cmLb22bNgChhRiQo=";
            allowedIPs = [
              "0.0.0.0/0"
              "::/0"
            ];
            endpoint = "router.chi1.routedbits.com:51033";
            dynamicEndpointRefreshSeconds = 5;
          }
      ];
        postSetup = ''
          ${pkgs.iproute2}/bin/ip -6 addr add "fe80::1033/64" peer "fe80::0207/64" dev wg4242420207
        '';
    };
    wg4242423914 = {
      listenPort = 23914;
      privateKeyFile = config.sops.secrets."wireguard/kioubit-private-key".path;
      allowedIPsAsRoutes = false;
      peers = [
          {
            publicKey = "6Cylr9h1xFduAO+5nyXhFI1XJ0+Sw9jCpCDvcqErF1s=";
            allowedIPs = [
              "0.0.0.0/0"
              "::/0"
            ];
            endpoint = "us2.g-load.eu:21033";
            dynamicEndpointRefreshSeconds = 5;
          }
      ];
        postSetup = ''
          ${pkgs.iproute2}/bin/ip -6 addr add "fe80::ade1/64" peer "fe80::ade0/64" dev wg4242423914
        '';
    };
    wg4242421588 = {
      listenPort = 21588;
      privateKeyFile = config.sops.secrets."wireguard/tech9-private-key".path;
      allowedIPsAsRoutes = false;
      peers = [
          {
            publicKey = "0kb8ffMcbx8oXZ3Ii5khOuCzmRqM2Cy0IslmrWtRGSk=";
            allowedIPs = [
              "0.0.0.0/0"
              "::/0"
            ];
            endpoint = "us-chi01.dn42.tech9.io:52581";
            dynamicEndpointRefreshSeconds = 5;
          }
      ];
        postSetup = ''
          ${pkgs.iproute2}/bin/ip -6 addr add "fe80::100/64" peer "fe80::1588/64" dev wg4242421588
        '';
    };
  };

  # TODO: Make a NixOS module out of this
  # networking.wireguard.interfaces = import peers/tunnels.nix rec {
  #   customTunnel =
  #     listenPort: privateKeyFile: publicKey: endpoint: name: tunnelIPv4: tunnelIPv6: localIPv4: localIPv6: isOspf: {
  #       listenPort = listenPort;
  #       privateKeyFile = privateKeyFile;
  #       allowedIPsAsRoutes = false;
  #       peers = [
  #         {
  #           publicKey = publicKey;
  #           allowedIPs = [
  #             "0.0.0.0/0"
  #             "::/0"
  #           ];
  #           endpoint = endpoint;
  #           dynamicEndpointRefreshSeconds = 5;
  #         }
  #       ];
  #       postSetup = ''
  #         ${lib.optionalString (
  #           tunnelIPv4 != null
  #         ) "${pkgs.iproute2}/bin/ip addr add ${localIPv4} peer ${tunnelIPv4} dev ${name}"}
  #         ${lib.optionalString (
  #           tunnelIPv6 != null
  #         ) "${pkgs.iproute2}/bin/ip -6 addr add ${localIPv6} peer ${tunnelIPv6} dev ${name}"}
  #         ${lib.optionalString isOspf "${pkgs.iproute2}/bin/ip -6 addr add ${defaultLocalIPv6} dev ${name}"}
  #       '';
  #     };
  #   tunnel =
  #     listenPort: privateKeyFile: publicKey: endpoint: name: tunnelIPv4: tunnelIPv6:
  #     customTunnel listenPort privateKeyFile publicKey endpoint name tunnelIPv4 tunnelIPv6
  #       defaultLocalIPv4
  #       defaultLocalIPv6
  #       false;
  #   ospf =
  #     listenPort: privateKeyFile: publicKey: endpoint: name: tunnelIPv4: tunnelIPv6: ULAIPv6:
  #     customTunnel listenPort privateKeyFile publicKey endpoint name tunnelIPv4 tunnelIPv6
  #       defaultLocalIPv4
  #       ULAIPv6
  #       true;
  # };
  sops.secrets = {
    "wireguard/routed-bits-private-key" = {
      sopsFile = ../secrets.yaml;
    };
    "wireguard/kioubit-private-key" = {
      sopsFile = ../secrets.yaml;
    };
    "wireguard/tech9-private-key" = {
      sopsFile = ../secrets.yaml;
    };
  };
}
