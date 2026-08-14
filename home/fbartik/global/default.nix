{
  pkgs,
  ...
}:
{
  imports = [
    ../../common
    ../features/cli
  ];

  home = {
    username = "fbartik";
    homeDirectory = if pkgs.stdenv.hostPlatform.isDarwin then "/Users/fbartik" else "/home/fbartik";
  };

  # Add stuff for your user as you see fit:
  # programs.neovim.enable = true;
  # home.packages = with pkgs; [
  #   ethtool
  #   gparted
  #   f2fs-tools
  # ];
}
