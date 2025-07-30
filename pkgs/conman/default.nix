{
  lib,
  freeipmi,
  autoreconfHook,
  pkg-config,
  fetchFromGitHub,
  tcp_wrappers,
  stdenv,
  expect,
  ...
}:
stdenv.mkDerivation rec {
  pname = "conman";
  version = "0.3.1";

  src = fetchFromGitHub {
    owner = "dun";
    repo = "conman";
    tag = "conman-${version}";
    hash = "sha256-CHWvHYTmTiEpEfHm3TF5aCKBOW2GsT9Vv4ehpj775NQ=";
  };

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
  ];

  buildInputs = [
    freeipmi # For libipmiconsole.so.2
    tcp_wrappers # For libwrap.so.0
    expect # For conman/*.exp scripts
  ];

  meta = with lib; {
    description = "ConMan: The Console Manager";
    homepage = "https://github.com/dun/conman";
    license = licenses.gpl3Plus;
    platforms = [ "x86_64-linux" ];
    maintainers = [ lib.maintainers.frantathefranta ];
  };

}
