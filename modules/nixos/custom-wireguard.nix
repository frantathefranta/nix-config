{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.custom-wireguard;
in
{
  options.services.custom-wireguard = {
    interfaces = mkOption {
      default = { };
      type =
        with lib.types;
        attrsOf (submodule {
          options = {
            listenPort = mkOption {
              default = null;
              type = types.nullOr types.int;
              description = ''
                Wireguard port
              '';
            };
            peerEndpoint = mkOption {
              default = null;
              type = types.nullOr types.str;
              description = ''
                Wireguard peer endpoint
              '';
            };
            peerPublicKey = mkOption {
              default = null;
              type = types.nullOr types.str;
              description = ''
                Wireguard peer endpoint
              '';
            };
            peerAddressV6 = mkOption {
              default = null;
              type = types.nullOr types.str;
              description = ''
                Wireguard peer link-local IPv6 address
              '';
            };
            localAddressV6 = mkOption {
              default = null;
              type = types.nullOr types.str;
              description = ''
                Wireguard local link-local IPv6 address
              '';
            };
          };
        });
    };
  };
  config = {
    sops.secrets = fold (a: b: a // b) { } (
      flip mapAttrsToList cfg.interfaces (
        interface: data: {
          "wireguard/${interface}" = {
            sopsFile = ../../hosts/${config.networking.hostName}/secrets.yaml;
          };
        }
      )
    );

    systemd.services.systemd-networkd.serviceConfig = fold (a: b: a // b) { } (
      flip mapAttrsToList cfg.interfaces (
        interface: data:
        let
          secretName = "wireguard/${interface}";
          secretPath = config.sops.secrets.${secretName}.path;
        in
        {
          LoadCredential = [
            "network.wireguard.private.${interface}:${secretPath}"
          ];
        }
      )
    );
    systemd.network.netdevs = builtins.mapAttrs (interface: data: {
      netdevConfig = {
        # TODO: This needs to be able to remove any "integer-" prefix
        Name = lib.strings.removePrefix "50-" interface;
        Kind = "wireguard";
      };
      wireguardConfig = {
        PrivateKey = "@network.wireguard.private.${interface}";
        ListenPort = data.listenPort;
      };
      wireguardPeers = [
        {
          Endpoint = data.peerEndpoint;
          PersistentKeepalive = 5;
          PublicKey = data.peerPublicKey;
          AllowedIPs = [
            "0.0.0.0/0"
            "::/0"
          ];
        }
      ];
    }) cfg.interfaces;

    systemd.network.networks = builtins.mapAttrs (interface: data: {
      # TODO: Same as above
      matchConfig.Name = lib.strings.removePrefix "50-" interface;
      addresses = [
        {
          Address = data.localAddressV6;
          Peer = data.peerAddressV6;
        }
      ];
      networkConfig = {
        LinkLocalAddressing = false;
      };
    }) cfg.interfaces;
  };
}
