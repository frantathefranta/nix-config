# WIP
{ lib, pkgs, ... }:
pkgs.stdenv.mkDerivation rec {
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

  installPhase = ''
    mkdir -p $out/bin $out/share/doc $out/share/man $out/share/conman/exec
    mv usr/bin/{conman,conmen} $out/bin/
    mv usr/sbin/conmand $out/bin/

    mv usr/share/man $out/share/
    mv usr/share/doc/conman/copyright $out/share/doc/
    mv usr/share/conman/lib $out/share/conman/
    mv usr/share/conman/exec/*.exp $out/share/conman/exec/

    for file in $out/bin/*; do
      chmod +w $file
      patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
               --set-rpath ${lib.makeLibraryPath [ pkgs.stdenv.cc.cc ]} \
               $file
    done
  '';
  dontStrip = true;

  meta = with lib; {
    description = "ConMan: The Console Manager";
    homepage = "https://github.com/dun/conman";
    license = licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
    maintainers = [ ];
  };

}
