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
            peerAddress = mkOption {
              default = null;
              type = types.nullOr types.str;
              description = ''
                Wireguard peer link-local address
              '';
            };
            localAddress = mkOption {
              default = null;
              type = types.nullOr types.str;
              description = ''
                Wireguard local link-local address
              '';
            };
          };
        });
      # name = lib.mkOption {
      #   type = lib.types.str;
      #   default = null;
      # };
    };
  };
  config =
    # let
    #   name = builtins.toString cfg.interfaces;
    #   privateKeyName = "${config.networking.hostName}/${name}";
    # in
    {
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
            Address = data.localAddress;
            Peer = data.peerAddress;
          }
        ];
        networkConfig = {
          LinkLocalAddressing = false;
        };
      }) cfg.interfaces;
    };

  #   systemd.newtork.netdevs."50-${}" = builtins.mapAttrs (interface: data: { name = data.listenPort; }) cfg.interfaces;
  #   systemd.network.netdevs."50-${cfg.interfaces}" = {
  #     netdevConfig = {
  #       Name = cfg.name;
  #       Kind = "wireguard";
  #     };
  #   };
  # };
}
