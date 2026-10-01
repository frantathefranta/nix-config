{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  fetchurl,
  nix-update-script,
  versionCheckHook,
  writableTmpDirAsHomeHook,
  ripgrep,
  fd,
  makeBinaryWrapper,
  stdenvNoCC,
  bun,
}:

buildNpmPackage (finalAttrs: {
  pname = "pi-coding-agent";
  version = "0.99.2";

  src = fetchFromGitHub {
    owner = "earendil-works";
    repo = "pi";
    tag = "v${finalAttrs.version}";
    hash = "sha256-ukN//DNSnCr9gZHKSzexAGEZu95eMzTGJLjLc5B+Hwo=";
  };

  npmDepsHash = "sha256-eKghIpCAKawZm0Uf2iG6y1fz21Z5jNnMiAFJ5Quj3GI=";

  # The generated provider catalog is absent from git. Restore the catalog
  # shipped with the matching npm release instead of fetching it during build.
  modelData = fetchurl {
    url = "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-${finalAttrs.version}.tgz";
    hash = "sha256-Cz34eRtIghbzCdkIeJKUp0S7Ybuq0SPZQJjlbflTjSU=";
  };

  preConfigure = ''
    mkdir -p packages/ai/src/providers/data
    tar --extract --gzip --file=${finalAttrs.modelData} \
      --directory=packages/ai/src/providers/data \
      --strip-components=4 \
      package/dist/providers/data
  '';

  npmWorkspace = "packages/coding-agent";
  npmRebuildFlags = [ "--ignore-scripts" ];

  nativeBuildInputs = [
    makeBinaryWrapper
    bun
  ];

  buildPhase = ''
    runHook preBuild

    npm run build:offline

    pushd packages/coding-agent
    bun build --compile --no-compile-autoload-bunfig \
      ./dist/bun/cli.js ./src/utils/image-resize-worker.ts \
      ./src/extensions/codemode/worker.ts \
      --outfile $TMPDIR/pi
    popd

    runHook postBuild
  '';

  dontNpmPrune = true;
  preInstall = ''
    npm prune --omit=dev --no-save --ignore-scripts
  '';

  postInstall = ''
    nm="$out/lib/node_modules/pi-monorepo/node_modules"

    # Workspace links point into the build tree. Retain built packages for
    # extension imports and SDK consumers, replacing those links with copies.
    for ws in chord ai agent client protocol telemetry tui codemode mcp durable server session-backends/sqlite-node; do
      pkg=$(node -p "require('./packages/$ws/package.json').name")
      if [ -L "$nm/$pkg" ]; then
        rm "$nm/$pkg"
        cp -r "packages/$ws" "$nm/$pkg"
      fi
    done
    find "$nm" -type l -lname '*/packages/*' -delete
    find "$nm/.bin" -xtype l -delete

    # Replace the Node launcher with the compiled Bun executable.
    install -Dm755 $TMPDIR/pi $out/bin/pi

    mkdir -p $out/share/pi
    cp packages/coding-agent/package.json $out/share/pi/package.json
    cp -r packages/coding-agent/dist/modes/interactive/theme $out/share/pi/theme
    cp -r packages/coding-agent/dist/modes/interactive/assets $out/share/pi/assets
    cp -r packages/coding-agent/dist/core/export-html $out/share/pi/export-html
    cp -r packages/coding-agent/docs packages/coding-agent/examples $out/share/pi/
    cp packages/coding-agent/README.md packages/coding-agent/CHANGELOG.md $out/share/pi/
    cp node_modules/@silvia-odwyer/photon-node/photon_rs_bg.wasm $out/share/pi/
  ''
  + lib.optionalString stdenvNoCC.hostPlatform.isDarwin ''
    # Avoid inspecting foreign ELF binaries during Darwin's audit-tmpdir.
    rm -rf \
      "$nm/@anthropic-ai/sandbox-runtime/dist/vendor/seccomp" \
      "$nm/@anthropic-ai/sandbox-runtime/vendor/seccomp" \
      "$nm/@earendil-works/pi-tui/native/linux"
  '';

  postFixup = ''
    wrapProgram $out/bin/pi --prefix PATH : ${
      lib.makeBinPath [
        ripgrep
        fd
      ]
    } \
      --set PI_PACKAGE_DIR $out/share/pi \
      --set-default PI_SKIP_VERSION_CHECK 1 \
      --set-default PI_TELEMETRY 0
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [
    writableTmpDirAsHomeHook
    versionCheckHook
  ];
  versionCheckKeepEnvironment = [ "HOME" ];
  versionCheckProgram = "${placeholder "out"}/bin/pi";
  versionCheckProgramArg = "--version";

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--flake"
      "--custom-dep"
      "modelData"
    ];
  };

  meta = {
    description = "Coding agent CLI with read, bash, edit, write tools and session management";
    homepage = "https://pi.dev/";
    downloadPage = "https://www.npmjs.com/package/@earendil-works/pi-coding-agent";
    changelog = "https://github.com/earendil-works/pi/blob/v${finalAttrs.version}/packages/coding-agent/CHANGELOG.md";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ frantathefranta ];
    mainProgram = "pi";
  };
})
