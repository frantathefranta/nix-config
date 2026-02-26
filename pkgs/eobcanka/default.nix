# Initial attempt to build conman from .deb
{
  lib,
  dpkg,
  fetchurl,
  autoPatchelfHook,
  stdenv,
  pcsclite,
  qt6,
  gtk3,
  openssl,
  libxxf86vm,
  ...
}:
stdenv.mkDerivation rec {
  pname = "eobcanka";
  version = "3.5.1";

  src = fetchurl {
    urls = [
      "https://info.identita.gov.cz/download/eObcanka.deb"
    ];
    hash = "sha256-EnkLvqcFzlQXETGhufq7m/Eabm3QEhihIcMh5U2BJjo=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    pcsclite
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qt5compat
    qt6.qtwebengine
    openssl
    libxxf86vm
    gtk3
  ];

  unpackPhase = "dpkg -x $src ./";

  installPhase = ''
    mkdir -p $out/bin $out/share/doc $out/share/man $out/lib
    mv opt/eObcanka/lib/lib* $out/lib
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
