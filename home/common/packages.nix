{ pkgs, ... }:

{
  home.packages =
    with pkgs;
    [
      btop # better top
      doggo # Better DNS
      fd # Better find
      httpie # Better curl
      iperf3
      jq # JSON pretty printer and manipulator
      mtr # traceroute replacement
      nmap
      ripgrep # Better grep
      tree
      viddy # Better watch
      wget # I will simply not learn curl syntax for downloading files
    ];
}
