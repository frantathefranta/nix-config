{
  lib,
  fetchurl,
  autoPatchelfHook,
  stdenv,
  xz,
  zlib,
  pciutils,
  util-linux,
  ...
}:
let
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
    buildInputs = [ zlib xz.out stdenv.cc.cc.lib ];
    # ICU soname 72 is not in nixpkgs (has 76); unused by Dell tools' basic XML parsing
    autoPatchelfIgnoreMissingDeps = [ "libicuuc.so.72" ];

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

    # Patch I2C bus: Dell DiagOS references /dev/i2c-1 but on Proxmox/NixOS
    # the TC654 fan controller lives on /dev/i2c-0.
    for xml in default_fan_list.xml default_temp_sensors.xml default_led_list.xml default_pl_list.xml; do
      find $out/share/dn-diags -name "$xml" -exec \
        sed -i 's|/dev/i2c-1|/dev/i2c-0|g' {} +
    done
  '';

  appendRunpaths = [ "$out/lib" ];

  dontStrip = true;

  meta = with lib; {
    description = "Dell DiagOS tools for VEP14xx/EDGE6xx appliances (fantool, ledtool, temptool, etc.)";
    homepage = "https://github.com/mhannis/VEP14xx";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    maintainers = [ ];
  };
}
