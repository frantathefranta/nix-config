{ pkgs, ... }:
{
  imports = [
    ./global
    ./features/kubectl
    ./features/productivity
    ./features/editor
  ];
  programs.claude-code = {
    enable = true;
    package = pkgs.unstable.claude-code;
  };
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
}
