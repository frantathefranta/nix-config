{ pkgs, ... }:
{
  imports = [
    ./global
    ./features/kubectl
    ./features/productivity
    ./features/productivity/pi
    ./features/editor
  ];
  home.packages = with pkgs; [
    # Binary only; the herdr config from features/productivity stays
    # off the bastion.
    unstable.herdr
  ];
  # Unstable Home Manager enables nushell shell integration for fzf by
  # default, asserting fzf >= 0.73; the stable nixpkgs pin is older.
  programs.fzf.enableNushellIntegration = false;
  programs.irssi = {
    enable = true;
    networks = {
      "hackint" = {
        server = {
          address = "irc.hackint.org";
          port = 6697;
        };
        nick = "franta";
      };
    };
  };
  programs.git.settings.commit.gpgSign = false;
}
