{
  imports = [
    ./global
    ./features/kubectl
    ./features/productivity
    ./features/editor
  ];
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
