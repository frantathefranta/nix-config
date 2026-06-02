{
  inputs,
  ...
}:

{
  imports = [
    inputs.nixos-dns.nixosModules.dns
  ];
  networking.domains = {
    enable = true;
    baseDomains = {
      "franta.dn42" = { };
      "infra.franta.us" = { };
    };
  };
}
