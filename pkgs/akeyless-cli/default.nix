{ fetchurl, stdenv, }:

let
  version = "latest";
  hash = "sha256-vBp8eWe4OlkfbCAtvYo7U1z0TJxqATe+jlC4U0PXEug=";
  # sha256 = "03x792gqgxfsiyd7m03p2hbdm4qnf4y6pdxr40qz5zf7a4rvmz58";
  src = fetchurl {
    url = "https://akeyless-cli.s3.us-east-2.amazonaws.com/cli/${version}/production/cli-linux-amd64";
    hash = hash;
  };
in
stdenv.mkDerivation {
  name = "akeyless-cli-${version}";
  src = src;
  phases = [ "installPhase" ];
  installPhase = ''
    mkdir -p $out/bin
    install -m755 ${src} $out/bin/akeyless
  '';
}
