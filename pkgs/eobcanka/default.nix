# eObcanka package - installs from .deb
# Uses buildFHSEnv because the binary has hardcoded /usr/lib64 paths for its
# PKCS#11 modules. Inside the FHS environment /usr/lib64 is a symlink to
# /usr/lib, where the P11 libs end up via targetPkgs.
{
  lib,
  buildFHSEnv,
  dpkg,
  fetchurl,
  autoPatchelfHook,
  stdenv,
  pcsclite,
  qt6,
  gtk3,
  openssl,
  libxxf86vm,
  xorg,
  xcb-util-cursor,
  libdrm,
  ...
}:

let
  inner = stdenv.mkDerivation {
    pname = "eobcanka-inner";
    version = "3.5.1";

    src = fetchurl {
      urls = [ "https://info.identita.gov.cz/download/eObcanka.deb" ];
      hash = "sha256-EnkLvqcFzlQXETGhufq7m/Eabm3QEhihIcMh5U2BJjo=";
    };

    nativeBuildInputs = [ dpkg autoPatchelfHook ];

    buildInputs = [
      pcsclite
      qt6.qtbase
      qt6.qtdeclarative
      qt6.qt5compat
      qt6.qtwebengine
      openssl
      libxxf86vm
      gtk3
      stdenv.cc.cc.lib
      xorg.libxcb
      xorg.xcbutilkeysyms
      xorg.xcbutilrenderutil
      xorg.xcbutilwm
      xorg.xcbutilimage
      xcb-util-cursor
      libdrm
    ];

    unpackPhase = "dpkg -x $src ./";

    installPhase = ''
      mkdir -p $out/bin $out/lib $out/share $out/local/etc/crplus

      # All P11 .so files, versioned files, and pin-provider executables live in
      # usr/lib/x86_64-linux-gnu/ in the deb.
      mv usr/lib/x86_64-linux-gnu/* $out/lib/

      # Those .so files include absolute symlinks (→ /usr/lib/x86_64-linux-gnu/...).
      # Fix them to be relative so they resolve inside $out/lib/.
      for f in $out/lib/*.so; do
        [ -L "$f" ] || continue
        base="$(basename "$(readlink "$f")")"
        [ -f "$out/lib/$base" ] && ln -sf "$base" "$f"
      done

      # Additional libs only present in opt/eObcanka/lib/ (not in x86_64-linux-gnu/).
      for extra in opt/eObcanka/lib/libcmprovp11.so opt/eObcanka/lib/libcryptoui.so; do
        [ -e "$extra" ] && mv "$extra" $out/lib/
      done

      # .sig files – app checks /usr/local/etc/crplus/sigs/x64 first, then /usr/lib64.
      # Serve them from /usr/lib64 (the FHS fallback) via $out/lib/.
      mv usr/local/etc/crplus/sigs/x64/* $out/lib/

      # .cfg files tell libeopproxyp11.so which P11 modules to load.
      # Patch the hardcoded /usr/lib/x86_64-linux-gnu/ prefix → /usr/lib64/
      # so modules are found via the FHS symlink inside the sandbox.
      for f in usr/local/etc/crplus/*.cfg; do
        sed 's|/usr/lib/x86_64-linux-gnu/|/usr/lib64/|g' "$f" \
          > "$out/local/etc/crplus/$(basename "$f")"
      done

      # Binaries + sibling files (eopcardman.sig, JSON configs)
      mv opt/eObcanka/SpravceKarty/* $out/bin/
      mv opt/eObcanka/Identifikace/* $out/bin/
      rm $out/bin/*.sh

      mv usr/share/* $out/share/
    '';

    # autoPatchelfHook modifies every ELF file it finds, including the P11 modules
    # and pin providers. The app verifies those files against .sig RSA signature
    # files at startup, so their on-disk bytes must be identical to the originals.
    # Re-extract the signed files from the .deb after autoPatchelf has finished.
    postFixup = ''
      tmpdir=$(mktemp -d)
      dpkg -x $src "$tmpdir"

      # Restore versioned P11 .so files (symlinks were not patched, only the
      # versioned targets; overwriting the targets restores valid signatures).
      for pat in libeopproxyp11 libeop2v1czep11 libeopczep11 libsa2v1czep11; do
        for f in "$tmpdir"/usr/lib/x86_64-linux-gnu/$pat.so.*; do
          [ -f "$f" ] && cp "$f" $out/lib/
        done
      done
      [ -f "$tmpdir/opt/eObcanka/lib/libcmprovp11.so" ] && \
        cp "$tmpdir/opt/eObcanka/lib/libcmprovp11.so" $out/lib/

      # Restore pin provider executables
      for bin in eop2v1czep11 eopczep11 sa2v1czep11; do
        for dir in "$tmpdir/opt/eObcanka/SpravceKarty" "$tmpdir/opt/eObcanka/Identifikace"; do
          [ -f "$dir/$bin" ] && cp "$dir/$bin" "$out/bin/$bin"
        done
      done

      rm -rf "$tmpdir"
    '';

    dontWrapQtApps = true;
    dontStrip = true;
  };
in
buildFHSEnv {
  name = "eopcardman";

  targetPkgs = _: [
    inner
    pcsclite
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qt5compat
    qt6.qtwebengine
    openssl
    gtk3
    libxxf86vm
    stdenv.cc.cc.lib
    xorg.libxcb
    xorg.xcbutil
    xorg.xcbutilkeysyms
    xorg.xcbutilrenderutil
    xorg.xcbutilwm
    xorg.xcbutilimage
    xcb-util-cursor
    libdrm
  ];

  # Sourced before runScript – sets Qt plugin paths using the FHS /usr/lib tree.
  profile = ''
    export QT_PLUGIN_PATH="/usr/lib/qt-6/plugins"
    export QML2_IMPORT_PATH="/usr/lib/qt-6/qml"
  '';

  runScript = "${inner}/bin/eopcardman";

  extraInstallCommands = ''
    # Also expose eopauthapp
    ln -s $out/bin/eopcardman $out/bin/eopauthapp
  '';

  meta = with lib; {
    description = "eObcanka - Czech eID card manager";
    homepage = "https://info.identita.gov.cz";
    platforms = [ "x86_64-linux" ];
    maintainers = [ ];
  };
}
