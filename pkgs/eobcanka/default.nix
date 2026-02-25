# Initial attempt to build conman from .deb
{
  lib,
  dpkg,
  fetchurl,
  autoPatchelfHook,
  stdenv,
  expect,
  ...
}:
stdenv.mkDerivation rec {
  pname = "eobcanka";
  version = "3.5.1";

  src = fetchurl {
    urls = [
      "https://info.identita.gov.cz/download/eObcanka.deb"
    ];
    sha256 = "1h7l42rhin2izsszr3bzpmgms34yx12x5422l5dk4dfczfqjri58";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
  ];

  # buildInputs = [
  #   freeipmi # For libipmiconsole.so.2
  #   tcp_wrappers # For libwrap.so.0
  #   expect # For conman/*.exp scripts
  # ];

  unpackPhase = "dpkg -x $src ./";

  installPhase = ''
    mkdir -p $out/bin $out/share/doc $out/share/man 
    mv opt/eObcanka/SpravceKarty/* $out/bin/
    mv opt/eObcanka/Identifikace/* $out/bin/

    mv usr/share/* $out/share/
  '';
  dontStrip = true;

  meta = with lib; {
    description = "eObcanka";
    homepage = "https://info.identita.gov.cz";
    # license = licenses.gpl3Plus;
    platforms = [ "x86_64-linux" ];
    maintainers = [ ];
  };

}
