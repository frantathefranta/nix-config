{ config, inputs, ... }:
{
  imports = [
    inputs.dn42-nix.nixosModules.peerfinder
  ];
  services.peerfinder-agent = {
    enable = true;
    secretKeyFile = config.sops.secrets.peerfinder.path;
  };

  sops.secrets.peerfinder = {
    sopsFile = ../../../${config.networking.hostName}/secrets.yaml;
    group = "peerfinder";
    mode = "0440";
  };

  networking.nftables.firewall.rules.allow_peerfinder = {
    from = [
      "untrusted"
    ];
    to = [ "fw" ];
    allowedTCPPorts = [ 9000 ];
  };
}
