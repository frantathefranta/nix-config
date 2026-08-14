{
  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      dates = "Tue, 3:00";
      extraArgs = "--keep-since 14d";
    };
    flake = "/home/fbartik/nix-config";
  };
}
