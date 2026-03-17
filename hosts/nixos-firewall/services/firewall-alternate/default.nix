{
  config,
  lib,
  pkgs,
  ...
}:

{
  networking = {
    firewall.enable = false;
    nat.enable = false;
    nftables = {
      enable = true;
      flushRuleset = true;
      ruleset = /* nftables */ ''
         
      '';
    };
  };
}
