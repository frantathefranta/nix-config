{
  stdenvNoCC,
  lib,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation {
  pname = "etBembo";
  version = "1.0";
  src = fetchFromGitHub {
    owner = "DavidBarts";
    repo = "ET_Bembo";
    rev = "b1824ac5bee3f54ef1ce88c9d6c7850f6c869818";
    hash = "sha256-9G0Umcu5dkwx+mh0k5vPS3nIBdStlR0wBkDVzahVBwg=";
  };

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/fonts/truetype
    cp -r $src/* $out/share/fonts/truetype
    runHook postInstall
  '';

  meta = {
    platforms = lib.platforms.all;
  };
}
