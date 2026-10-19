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
let
  isLinuxX64 = stdenvNoCC.hostPlatform.system == "x86_64-linux";
  # The standard Linux x64 Bun binary requires AVX2, which hydrogen's N5105 lacks.
  bunForBuild =
    if stdenvNoCC.buildPlatform.system == "x86_64-linux" then
      bun.overrideAttrs (oldAttrs: {
        src = fetchurl {
          url = "https://github.com/oven-sh/bun/releases/download/bun-v${oldAttrs.version}/bun-linux-x64-baseline.zip";
          hash = "sha256-nYokKSpwaAkCBdqsCloiP19pc29Sh+N7+I07QDHtx1A=";
        };
      })
    else
      bun;
in
buildNpmPackage (finalAttrs: {
  pname = "pi-coding-agent";
  version = "1.3.0";

  src = fetchFromGitHub {
    owner = "earendil-works";
    repo = "pi";
    tag = "v${finalAttrs.version}";
    hash = "sha256-AsutbwnjiwwLkB5tqLW+1GdGZyLmXsU0W+SNdNhJu7U=";
  };

  npmDepsHash = "sha256-+gFyvrhkCsF99oNvs0gBmLXnDW0hWnZI/wFId7UbI6Q=";

  # The generated provider catalog is absent from git. Restore the catalog
  # shipped with the matching npm release instead of fetching it during build.
  modelData = fetchurl {
    url = "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-${finalAttrs.version}.tgz";
    hash = "sha256-U0PhY5vzQ73DNE3zrWwxwFpQtoutB6xrzhCJDUtrimE=";
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
    bunForBuild
  ];

  buildPhase = ''
    runHook preBuild

    npm run build:offline

    pushd packages/coding-agent
    bun build --compile ${lib.optionalString isLinuxX64 "--target=bun-linux-x64-baseline"} \
      --no-compile-autoload-bunfig \
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
    for manifest in packages/*/package.json; do
      ws=$(dirname "$manifest")
      pkg=$(node -p "require('./$manifest').name")
      if [ -L "$nm/$pkg" ]; then
        rm "$nm/$pkg"
        cp -r "$ws" "$nm/$pkg"
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
