{ config, lib, pkgs, ... }:

{
  programs.password-store = {
    enable = true;
    package = pkgs.passage;
  };
}
