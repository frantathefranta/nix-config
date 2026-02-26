{ inputs, lib, ... }:
{
  imports = [
    inputs.srvos.nixosModules.server
    ../optional/prometheus-node-exporter.nix
    ../optional/autoupgrade.nix
  ];

  # Fast boot for headless systems
  # boot.loader.timeout = lib.mkDefault 1;

  # No graphical boot
  # boot.plymouth.enable = lib.mkDefault false;

  # srvos handles documentation settings (disables all by default)
}
