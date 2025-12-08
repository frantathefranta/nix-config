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
              type = types.nullOr types.str;
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
          };
        });
      # name = lib.mkOption {
      #   type = lib.types.str;
      #   default = null;
      # };
    };
  };
  config =
    let
      name = builtins.toString cfg.interfaces;
      privateKeyName = "${config.networking.hostName}/${name}";
    in
    {
      sops.secrets = {
        "wireguard/${privateKeyName}" = {
          sopsFile = ../../hosts/common/secrets.yaml;
        };
      };

      systemd.services.systemd-networkd.serviceConfig = {
        LoadCredential =
          let
            secretPath = config.sops.secrets."wireguard/${privateKeyName}".path;
          in
          [
            "network.wireguard.private.${name}:${secretPath}"
          ];
      };
      systemd.network.netdevs = builtins.mapAttrs (interface: data: {
        netdevConfig = {
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
