{
  config,
  inputs,
  lib,
  ...
}:

{
  imports = [
    inputs.nixos-dns.nixosModules.dns
  ];
  networking.domains = {
    enable = true;
    baseDomains =
      { "franta.dn42" = { }; }
      // lib.optionalAttrs (config.networking.domain == "infra.franta.us") { "infra.franta.us" = { }; }
      // lib.optionalAttrs (config.networking.domain == "cloud.franta.us") { "cloud.franta.us" = { }; };
  };
}
