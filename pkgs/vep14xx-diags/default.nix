{
  lib,
  fetchurl,
  autoPatchelfHook,
  stdenv,
  xz,
  zlib,
  pciutils,
  util-linux,
  sku ? "SKU4",
  ...
}:
let
  # Debian Bookworm ships ICU 72; nixpkgs has moved past this soname.
  # Needed at runtime by the Bookworm libxml2 below.
  icu72-compat = stdenv.mkDerivation {
    pname = "icu72-compat";
    version = "72.1";

    src = fetchurl {
      url = "https://deb.debian.org/debian/pool/main/i/icu/libicu72_72.1-3+deb12u1_amd64.deb";
      name = "libicu72-bookworm.deb";
      sha256 = "f7f6f99c6d7b025914df2447fc93e11d22c44c0c8bdd8b6f36691c9e7ddcef88";
    };

    nativeBuildInputs = [ autoPatchelfHook ];
    buildInputs = [ stdenv.cc.cc.lib ];

    unpackPhase = ''
      ar x $src
      tar xf data.tar.* --no-same-permissions --no-same-owner
    '';

    installPhase = ''
      mkdir -p $out/lib
      cp -a usr/lib/x86_64-linux-gnu/libicu*.so.* $out/lib/
    '';

    dontStrip = true;
  };

  # The Dell binaries expect libxml2.so.2 (Debian Bookworm's soname).
  # Current nixpkgs libxml2 2.14+ ships libxml2.so.16 with different version
  # symbols, so we use the matching Debian library directly.
  libxml2-compat = stdenv.mkDerivation {
    pname = "libxml2-compat";
    version = "2.9.14";

    src = fetchurl {
      url = "https://deb.debian.org/debian/pool/main/libx/libxml2/libxml2_2.9.14+dfsg-1.3~deb12u5_amd64.deb";
      name = "libxml2-2.9.14-bookworm.deb";
      sha256 = "1mkvhp8av9prm0q9gnhsvc643zbb05p4hz7lygg9nbghmlhd26i6";
    };

    nativeBuildInputs = [ autoPatchelfHook ];
    buildInputs = [ zlib xz.out stdenv.cc.cc.lib icu72-compat ];

    unpackPhase = ''
      ar x $src
      tar xf data.tar.* --no-same-permissions --no-same-owner
    '';

    installPhase = ''
      mkdir -p $out/lib
      cp -a usr/lib/x86_64-linux-gnu/libxml2.so.* $out/lib/
    '';

    dontStrip = true;
  };
in
stdenv.mkDerivation rec {
  pname = "vep14xx-diags";
  version = "3.43.4.81-26";

  src = fetchurl {
    url = "https://github.com/mhannis/VEP14xx/raw/main/dn-diags-VEP1400-DiagOS-${version}-2022-12-08.deb";
    sha256 = "0xqm7vn8yl8i6wwh4wa5f9acf0x20x08s6g7ij38iqpf7dy7bzlm";
  };

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
    libxml2-compat
    zlib
    pciutils
    util-linux.lib # libuuid.so.1
    stdenv.cc.cc.lib # libstdc++, libgcc_s
  ];

  # dpkg -x fails in the sandbox because the .deb has setgid bits on directories.
  # Extract manually with ar + tar instead.
  unpackPhase = ''
    ar x $src
    tar xf data.tar.* --no-same-permissions --no-same-owner
  '';

  installPhase = ''
    # Binaries
    mkdir -p $out/bin
    for f in opt/dellemc/diag/bin/*; do
      [ -f "$f" ] && [ -x "$f" ] && cp "$f" $out/bin/
    done

    # Shared library (needed by all tools at runtime)
    mkdir -p $out/lib
    cp -a opt/dellemc/diag/lib/libdiag_util.so* $out/lib/

    # XML config files and databases
    mkdir -p $out/share/dn-diags
    cp -r etc/dn/diag/* $out/share/dn-diags/

    # default_fan_list.xml only exists in SKU subdirectories; copy the
    # selected SKU's version to the top level where the tools expect it.
    cp "etc/dn/diag/${sku}/default_fan_list.xml" "$out/share/dn-diags/"
  '';

  appendRunpaths = [ "$out/lib" ];

  doInstallCheck = true;
  installCheckPhase = ''
    echo "Checking for unresolved shared library dependencies…"
    local fail=0
    for f in $out/bin/* $out/lib/*.so*; do
      [ -f "$f" ] || continue
      [ -L "$f" ] && continue
      if ldd "$f" 2>&1 | grep -q "not found"; then
        echo "MISSING deps in $f:"
        ldd "$f" | grep "not found"
        fail=1
      fi
    done
    [ "$fail" -eq 0 ] || exit 1
  '';

  dontStrip = true;

  meta = with lib; {
    description = "Dell DiagOS tools for VEP14xx/EDGE6xx appliances (fantool, ledtool, temptool, etc.)";
    homepage = "https://github.com/mhannis/VEP14xx";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    maintainers = [ ];
  };
}
