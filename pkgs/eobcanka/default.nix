# eObcanka package - installs from .deb
# Uses buildFHSEnv because the binary has hardcoded /usr/lib64 paths for its
# PKCS#11 modules. Inside the FHS environment /usr/lib64 is a symlink to
# /usr/lib, where the P11 libs end up via targetPkgs.
#
# P11 modules and pin providers live in a separate derivation (p11modules) with
# dontFixup = true so autoPatchelfHook never touches them — the app verifies
# their on-disk bytes against .sig RSA signature files at startup.
{
  lib,
  buildFHSEnv,
  writeShellScript,
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
  src = fetchurl {
    urls = [ "https://info.identita.gov.cz/download/eObcanka.deb" ];
    hash = "sha256-EnkLvqcFzlQXETGhufq7m/Eabm3QEhihIcMh5U2BJjo=";
  };

  # P11 modules and pin providers extracted without any ELF patching.
  # dontFixup = true skips autoPatchelfHook, stripping, and all other fixup.
  p11modules = stdenv.mkDerivation {
    pname = "eobcanka-p11";
    version = "3.5.1";
    inherit src;
    nativeBuildInputs = [ dpkg ];
    unpackPhase = "dpkg -x $src ./";
    installPhase = ''
      mkdir -p $out/lib $out/local/etc/crplus/sigs/x64

      # Versioned .so files and their unversioned symlinks
      for pat in libeopproxyp11 libeop2v1czep11 libeopczep11 libsa2v1czep11; do
        cp -P usr/lib/x86_64-linux-gnu/$pat.so* $out/lib/ 2>/dev/null || true
      done
      # Fix absolute symlinks to be relative
      for link in $out/lib/*.so; do
        [ -L "$link" ] || continue
        base="$(basename "$(readlink "$link")")"
        [ -f "$out/lib/$base" ] && ln -sf "$base" "$link"
      done
      [ -f opt/eObcanka/lib/libcmprovp11.so ] && \
        cp opt/eObcanka/lib/libcmprovp11.so $out/lib/

      # Pin provider executables – also live in usr/lib/x86_64-linux-gnu/ so the
      # app finds them at /usr/lib64/. Put them in $out/lib/ to match.
      for bin in eop2v1czep11 eopczep11 sa2v1czep11; do
        [ -f "usr/lib/x86_64-linux-gnu/$bin" ] && \
          cp "usr/lib/x86_64-linux-gnu/$bin" $out/lib/
      done

      # .sig files – serve from the primary path the app checks first and from
      # the /usr/lib64 fallback, so both report Found rather than Not found.
      cp usr/local/etc/crplus/sigs/x64/* $out/local/etc/crplus/sigs/x64/
      cp usr/local/etc/crplus/sigs/x64/* $out/lib/
    '';

    dontStrip = true;
    dontFixup = true;
  };

  inner = stdenv.mkDerivation {
    pname = "eobcanka-inner";
    version = "3.5.1";
    inherit src;

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

    # The FHS env provides all libs at runtime; allow autoPatchelf to skip
    # anything it can't resolve at build time.
    autoPatchelfIgnoreMissingDeps = true;

    unpackPhase = "dpkg -x $src ./";

    installPhase = ''
      mkdir -p $out/lib $out/share $out/local/etc/crplus \
               $out/eobcanka/SpravceKarty $out/eobcanka/Identifikace

      # Non-P11 libs (P11 modules and pin providers come from p11modules).
      mv usr/lib/x86_64-linux-gnu/* $out/lib/
      rm -f $out/lib/libeopproxyp11.so* \
            $out/lib/libeop2v1czep11.so* \
            $out/lib/libeopczep11.so* \
            $out/lib/libsa2v1czep11.so* \
            $out/lib/eop2v1czep11 \
            $out/lib/eopczep11 \
            $out/lib/sa2v1czep11
      [ -f opt/eObcanka/lib/libcryptoui.so ] && mv opt/eObcanka/lib/libcryptoui.so $out/lib/

      # Install binaries into the original /opt/eObcanka/ directory structure so
      # the hardcoded installRoot path and sibling-file lookups work at runtime.
      for f in opt/eObcanka/SpravceKarty/*; do
        case "$(basename "$f")" in
          eop2v1czep11|eopczep11|sa2v1czep11|*.sh) ;;
          *) mv "$f" $out/eobcanka/SpravceKarty/ ;;
        esac
      done
      for f in opt/eObcanka/Identifikace/*; do
        case "$(basename "$f")" in
          eop2v1czep11|eopczep11|sa2v1czep11|*.sh) ;;
          *) mv "$f" $out/eobcanka/Identifikace/ ;;
        esac
      done
      # Any top-level files directly in opt/eObcanka/ (e.g. version file)
      for f in opt/eObcanka/*; do
        [ -f "$f" ] && mv "$f" $out/eobcanka/
      done

      # .cfg files – patch module paths to /usr/lib64/ for the FHS symlink.
      for f in usr/local/etc/crplus/*.cfg; do
        sed 's|/usr/lib/x86_64-linux-gnu/|/usr/lib64/|g' "$f" \
          > "$out/local/etc/crplus/$(basename "$f")"
      done

      mv usr/share/* $out/share/
    '';

    dontWrapQtApps = true;
    dontStrip = true;
  };
in
buildFHSEnv {
  name = "eopcardman";

  targetPkgs = _: [
    inner
    p11modules
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

  # Bind-mount the eobcanka binaries at their hardcoded installRoot so the
  # version file, AppSettings.json, and other sibling-file lookups work.
  # bwrap's --dir creates /opt and /opt/eObcanka in the sandbox namespace.
  extraBwrapArgs = [
    "--dir" "/opt/eObcanka"
    "--ro-bind" "${inner}/eobcanka" "/opt/eObcanka"
  ];

  # Dispatch to the correct binary using its in-FHS path so argv[0]-derived
  # paths (sysProfilePath) also resolve to /opt/eObcanka/... at runtime.
  runScript = writeShellScript "eobcanka-run" ''
    if [ "''${EOP_APP:-}" = "eopauthapp" ]; then
      exec /opt/eObcanka/Identifikace/eopauthapp "$@"
    else
      exec /opt/eObcanka/SpravceKarty/eopcardman "$@"
    fi
  '';

  extraInstallCommands = ''
    # eopauthapp wrapper: sets EOP_APP before entering the bwrap sandbox so
    # runScript knows which binary to launch. bwrap inherits the env var.
    printf '#!/bin/sh\nexec env EOP_APP=eopauthapp %s "$@"\n' \
      "$out/bin/eopcardman" > $out/bin/eopauthapp
    chmod +x $out/bin/eopauthapp
  '';

  meta = with lib; {
    description = "eObcanka - Czech eID card manager";
    homepage = "https://info.identita.gov.cz";
    platforms = [ "x86_64-linux" ];
    maintainers = [ ];
  };
}
