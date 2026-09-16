{
  inputs,
  lib,
  ...
}: {
  imports = [
    inputs.hardware.nixosModules.common-cpu-intel
    inputs.hardware.nixosModules.common-pc-ssd

    ./hardware-configuration.nix
    # Dell Edge 610 / VEP1400 tweaks: 5.10 kernel, i2c modules,
    # SFP TX-enable service, diag tooling, runbook
    ../installer-iso/edge610-diag.nix

    ../common/global
    ../common/users/fbartik
    ../common/roles/server.nix
    ../common/optional/secure-boot.nix
  ];

  networking = {
    hostName = "neon";
    domain = "infra.franta.us";

    # TODO: once an IP is assigned, add:
    # - meta.ipam.host = { ipv4 = "..."; ipv6Suffix = "..."; };
    # - networking.domains.subDomains.<fqdn>.{a,aaaa}.data
    # - systemd.network.networks."10-<sfp-if>" = { ... };
  };

  # Headless: everything on the Micro-USB serial port (115200 8N1),
  # same as nixos-firewall (also a VEP14xx)
  boot.kernelParams = ["console=ttyS0,115200n8"];

  time.timeZone = "America/Detroit";
  system.stateVersion = "26.05";
}
