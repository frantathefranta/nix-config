{ inputs, lib, ... }:
{
  imports = [
    inputs.srvos.nixosModules.server
    ../optional/prometheus-node-exporter.nix
    ../optional/autoupgrade.nix
  ];

  networking = {
    firewall.enable = lib.mkDefault true;
    search = lib.mkDefault [
      "infra.franta.us"
      "franta.us"
    ];
    domain = lib.mkDefault "infra.franta.us";
    nameservers = lib.mkDefault [
      "10.33.10.0"
      "10.33.10.1"
    ];
  };
  # Fast boot for headless systems
  # boot.loader.timeout = lib.mkDefault 1;

  # No graphical boot
  # boot.plymouth.enable = lib.mkDefault false;

  # srvos handles documentation settings (disables all by default)
}
