{
  osConfig,
  config,
  lib,
  pkgs,
  ...
}:

{
  services.gpg-agent = {
    enable = true;
    # enableSshSupport = true;
    # sshKeys = [ "149F16412997785363112F3DBD713BC91D51B831" ];
    enableExtraSocket = true;
    pinentry.package =
      if osConfig ? services.desktopManager.plasma6.enable && osConfig.services.desktopManager.plasma6.enable
      then pkgs.pinentry-qt
      else if pkgs.stdenv.isDarwin
      then pkgs.pinentry_mac
      else pkgs.pinentry-tty;
  };
  programs =
    let
      fixGpg = /* bash */ ''
        gpgconf --launch gpg-agent
      '';
    in
    {
      # Start gpg-agent if it's not running or tunneled in
      # SSH does not start it automatically, so this is needed to avoid having to use a gpg command at startup
      # https://www.gnupg.org/faq/whats-new-in-2.1.html#autostart
      bash.profileExtra = fixGpg;
      fish.loginShellInit = fixGpg;
      zsh.loginExtra = fixGpg;
      nushell.extraLogin = fixGpg;

      gpg = {
        enable = true;
        settings = {
          trust-model = "tofu+pgp";
        };
        publicKeys = [
          {
            source = ../../pgp.asc;
            trust = 5;
          }
        ];
      };
    };
}
