{
  config,
  inputs,
  pkgs,
  ...
}:

{
  imports = [
    inputs.hardware.nixosModules.lenovo-thinkpad-t14-amd-gen1
    ./hardware-configuration.nix
    ./services
    ../common/global
    ../common/users/fbartik
    ../common/roles/workstation.nix

    ../common/optional/kde.nix
    ../common/optional/fwupd.nix
    ../common/optional/evremap.nix
  ];
  networking = {
    hostName = "silicium";
    nameservers = [ ];
    useNetworkd = true;
  };
  systemd = {
    network = {
      enable = true;
      wait-online = {
        enable = true;
        extraArgs = [
          "--any"
          "--interface=wlp3s0"
          "--interface=enp5s0"
        ];
      };
      networks."20-enp5s0" = {
        matchConfig.Name = "enp5s0";
        networkConfig = {
          DHCP = "yes";
          IPv6AcceptRA = true;
        };
        dhcpV4Config.RouteMetric = 10;
      };
      networks."30-wlp3s0" = {
        matchConfig.Name = "wlp3s0";
        networkConfig = {
          DHCP = "ipv4";
          IPv6AcceptRA = true;
        };
        ipv6AcceptRAConfig.RouterDenyList = [ "fe80::1c7d:ad2e:acf4:e622" ]; # Block the darn Apple TV ULA
        dhcpV4Config.RouteMetric = 100;
      };
      netdevs."50-wg_dn42" = {
        netdevConfig = {
          Name = "wg_dn42";
          Kind = "wireguard";
        };
        wireguardConfig = {
          PrivateKey = "@wg_dn42_key";
          ListenPort = 51820;
          RouteTable = "main";
        };
        wireguardPeers = [
          {
            PublicKey = "homewu6grFdjuoFxfXh1hLNdB9wvaO1m7/ZtCe1o/1o=";
            Endpoint = "molybdenum.infra.franta.us:51820";
            AllowedIPs = [
              "fd00::/8"
            ];
          }
        ];
      };
      networks."50_wg_dn42" = {
        matchConfig.Name = "wg_dn42";
        dns = [ "fdb7:c21f:f30f:53::" ];
        domains = [
          "~dn42"
          "~d.f.ip6.arpa"
        ];
        addresses = [
          {
            Address = "fdb7:c21f:f30f:98::2/128";
          }
        ];
      };
    };
  };
  environment.systemPackages = [ pkgs.wireguard-tools ];
  security.pki.certificateFiles = [ "${pkgs.dn42-cacert}/etc/ssl/certs/dn42-ca.crt" ];
  systemd.services.systemd-networkd.serviceConfig = {
    LoadCredential = [
      "wg_dn42_key:${config.sops.secrets."wireguard/50-wg_dn42".path}"
    ];
  };
  sops.secrets = {
    "wireguard/50-wg_dn42" = {
      sopsFile = ./secrets.yaml;
    };
  };

  hardware.enableAllFirmware = true;
  services.fprintd.enable = true;

  nixpkgs.overlays = [ inputs.nix-cachyos-kernel.overlays.pinned ];
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-x86_64-v3;
  # Binary cache
  nix.settings.substituters = [ "https://attic.xuyh0120.win/lantian" ];
  nix.settings.trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];
  system.stateVersion = "25.11";
}
