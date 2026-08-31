{  pkgs, ... }:

{
  home.packages = with pkgs; [
    tea
    tea-dash
  ];
}
