{ config, lib, ... }:
{

  programs._1password.enable = true;
  programs._1password-gui = lib.mkIf (config.services.xserver.enable == true) {
    enable = true;
    # Certain features, including CLI integration and system authentication support,
    # require enabling PolKit integration on some desktop environments (e.g. Plasma).
    polkitPolicyOwners = [ "franta" ];
  };
}
