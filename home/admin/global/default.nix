{ ... }:
{
  imports = [
    ../../common
    ./fish.nix
  ];

  home = {
    username = "admin";
    homeDirectory = "/home/admin";
  };
}
