{ config, lib, osConfig, ... }:
let
  hostname = osConfig.networking.hostName;

  # Central device registry — all known Syncthing devices
  allDevices = {
    talos-maxi = {
      id = "XBDGU4R-GJ2XHAL-J7VRHZ2-2X3IOAF-5REKOM2-LY2FZ2T-M6ZI2CM-XLKNSAE";
    };
    nix-bastion = {
      id = "XK26RI6-4LJ5D4K-3ONG7U3-RE3L43Q-T6I6DZD-AEQWFCL-VJ5QAVP-VYBBNAB";
    };
    lanthanum = {
      id = "YU4VLJP-RV3ZTYF-3OZY25F-32Y3DH3-QT4FEZ4-Q2O75WJ-354LXAZ-M2NYMAM";
    };
    # silicium = {
    #   id = "PLACEHOLDER-SILICIUM-ID";
    # };
    # Add more devices as needed
  };

  # Hubs connect to all other devices (and to each other)
  # Spokes connect only to hub hosts
  hubHosts = [ "nix-bastion" "talos-maxi" ];

  isHub = builtins.elem hostname hubHosts;

  devicesForHost =
    if isHub
    then lib.filterAttrs (name: _: name != hostname) allDevices
    else lib.filterAttrs (name: _: builtins.elem name hubHosts) allDevices;

  # All other device names (excluding self) — used for folder sharing
  otherDevices = builtins.attrNames (lib.filterAttrs (name: _: name != hostname) devicesForHost);

  # Folders synced to all connected devices
  globalFolders = {
    "syncthing" = {
      path = "~/syncthing";
      devices = otherDevices;
    };
  };

  # Per-host additional folders (on top of global ones)
  extraFoldersForHost = {
    # nix-bastion = {
    #   "backups" = {
    #     path = "~/backups";
    #     devices = [ "talos-maxi" ];
    #   };
    # };
  };

  hostFolders = globalFolders // (extraFoldersForHost.${hostname} or {});

  # Per-host secrets file for syncthing cert and key
  hostSecretsFile = ../../../.. + "/hosts/${hostname}/secrets.yaml";
in
{
  sops.secrets."syncthing/cert" = {
    sopsFile = hostSecretsFile;
  };
  sops.secrets."syncthing/key" = {
    sopsFile = hostSecretsFile;
  };

  services.syncthing = {
    enable = true;
    cert = config.sops.secrets."syncthing/cert".path;
    key = config.sops.secrets."syncthing/key".path;
    overrideDevices = true;
    overrideFolders = true;
    settings = {
      options.localAnnounceEnabled = true;
      devices = lib.mapAttrs (_name: cfg: { inherit (cfg) id; }) devicesForHost;
      folders = lib.mapAttrs (_name: cfg: {
        inherit (cfg) path devices;
      }) hostFolders;
    };
  };
}
