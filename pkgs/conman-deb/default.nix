# Initial attempt to build conman from .deb
{
  lib,
  dpkg,
  freeipmi,
  fetchurl,
  autoPatchelfHook,
  tcp_wrappers,
  stdenv,
  expect,
  ...
}:
stdenv.mkDerivation rec {
  pname = "conman-deb";
  version = "0.3.1-1";

  src = fetchurl {
    urls = [
      "mirror://debian/pool/main/c/conman/conman_${version}_amd64.deb"
    ];
    sha256 = "1h7l42rhin2izsszr3bzpmgms34yx12x5422l5dk4dfczfqjri58";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
  ];

  buildInputs = [
    freeipmi # For libipmiconsole.so.2
    tcp_wrappers # For libwrap.so.0
    expect # For conman/*.exp scripts
  ];

  unpackPhase = "dpkg -x $src ./";

  installPhase = ''
    mkdir -p $out/bin $out/share/doc $out/share/man $out/share/conman/exec
    mv usr/bin/{conman,conmen} $out/bin/
    mv usr/sbin/conmand $out/bin/

    mv usr/share/man $out/share/
    mv usr/share/doc/conman/copyright $out/share/doc/
    mv usr/share/conman/lib $out/share/conman/
    mv usr/share/conman/exec/*.exp $out/share/conman/exec/
  '';
  dontStrip = true;

  meta = with lib; {
    description = "ConMan: The Console Manager";
    homepage = "https://github.com/dun/conman";
    license = licenses.gpl3Plus;
    platforms = [ "x86_64-linux" ];
    maintainers = [ ];
  };

}
