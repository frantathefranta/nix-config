{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.services.custom-wireguard;

  # Strip any leading "digits-" prefix from the interface key to get the actual name.
  interfaceName = name:
    let
      m = builtins.match "([0-9]+-)(.*)" name;
    in
    if m != null then builtins.elemAt m 1 else name;
in
{
  options.services.custom-wireguard = {
    secretsFile = mkOption {
      default = ../../hosts/${config.networking.hostName}/secrets.yaml;
      type = types.path;
      description = ''
        Path to the sops secrets file containing Wireguard private keys.
      '';
    };
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
                Wireguard peer public key
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
            peerAddressV4 = mkOption {
              default = null;
              type = types.nullOr types.str;
              description = ''
                Wireguard peer link-local IPv4 address
              '';
            };
            localAddressV4 = mkOption {
              default = null;
              type = types.nullOr types.str;
              description = ''
                Wireguard local link-local IPv4 address
              '';
            };
            persistentKeepalive = mkOption {
              default = 25;
              type = types.int;
              description = ''
                Wireguard persistent keepalive interval in seconds
              '';
            };
            vrf = mkOption {
              default = null;
              type = types.nullOr types.str;
              description = ''
                Which VRF this interface should be added to
              '';
            };
          };
        });
    };
  };
  config = {
    sops.secrets = lib.mkMerge (
      flip mapAttrsToList cfg.interfaces (
        interface: _data: {
          "wireguard/${interface}" = {
            sopsFile = cfg.secretsFile;
          };
        }
      )
    );
    systemd.services.systemd-networkd.serviceConfig = lib.mkMerge (
      flip mapAttrsToList cfg.interfaces (
        interface: _data:
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
        Name = interfaceName interface;
        Kind = "wireguard";
      };
      wireguardConfig = {
        PrivateKey = "@network.wireguard.private.${interface}";
      } // lib.optionalAttrs (data.listenPort != null) {
        ListenPort = data.listenPort;
      };
      wireguardPeers = [
        ({
          PersistentKeepalive = data.persistentKeepalive;
          PublicKey = data.peerPublicKey;
          AllowedIPs = [
            "0.0.0.0/0"
            "::/0"
          ];
        } // lib.optionalAttrs (data.peerEndpoint != null) {
          Endpoint = data.peerEndpoint;
        })
      ];
    }) cfg.interfaces;

    systemd.network.networks = builtins.mapAttrs (interface: data: {
      matchConfig.Name = interfaceName interface;
      addresses =
        lib.optional (data.localAddressV6 != null) {
          Address = data.localAddressV6;
          Peer = data.peerAddressV6;
        }
        ++ lib.optional (data.localAddressV4 != null) {
          Address = data.localAddressV4;
          Peer = data.peerAddressV4;
        };
      networkConfig = {
        LinkLocalAddressing = false;
      } // lib.optionalAttrs (data.vrf != null) {
        VRF = data.vrf;
      };
    }) cfg.interfaces;
  };
}
