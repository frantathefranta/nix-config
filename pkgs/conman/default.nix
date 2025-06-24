# WIP
{ config, lib, pkgs, ... }:
let
  conman = pkgs.stdenv.mkDerivation rec {
    pname = "conman";
    version = "0.3.1-1";

    src = pkgs.fetchurl {
      urls = [
        "mirror://debian/pool/main/c/conman/conman_${version}_amd64.deb"
      ];
      sha256 = "1h7l42rhin2izsszr3bzpmgms34yx12x5422l5dk4dfczfqjri58";
    };

    nativeBuildInputs = [ pkgs.dpkg ];

    unpackPhase = "dpkg -x $src ./";


  }
{

}
