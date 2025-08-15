{ pkgs, ... }:

{
  home.packages = with pkgs; [
    aporetic
  ];
}
