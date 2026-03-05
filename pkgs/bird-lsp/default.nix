{
  lib,
  fetchFromGitHub,
  fetchPnpmDeps,
  nodejs,
  pnpm_10,
  pnpmConfigHook,
  typescript,
  stdenv,
  pkgsCross,
}:
let
  version = "0.0.1-0";

  src = fetchFromGitHub {
    owner = "bird-chinese-community";
    repo = "BIRD-LSP";
    tag = "v${version}";
    hash = "sha256-DrA+Olc++aRJkFTytxONN7kR+baOnw/7yKyET2s87fU=";
  };

  # Build the dprint BIRD formatter plugin as wasm32-unknown-unknown.
  # Use pkgsCross.wasi32 to pass nixpkgs platform checks (wasm32-wasi is a known
  # platform), but override CARGO_BUILD_TARGET to wasm32-unknown-unknown so the
  # code compiles correctly — the wasm_plugin module is gated on target_os = "unknown".
  dprintPluginBirdWasm = pkgsCross.wasi32.rustPlatform.buildRustPackage {
    pname = "dprint-plugin-bird-wasm";
    version = "0.0.1";

    src = "${src}/packages/@birdcc/dprint-plugin-bird";

    cargoLock = {
      lockFile = "${src}/packages/@birdcc/dprint-plugin-bird/Cargo.lock";
    };

    buildFeatures = [ "wasm" ];
    CARGO_BUILD_TARGET = "wasm32-unknown-unknown";
    doCheck = false;

    installPhase = ''
      runHook preInstall
      install -Dm644 \
        target/wasm32-unknown-unknown/release/dprint_plugin_bird.wasm \
        $out/dprint-plugin-bird.wasm
      runHook postInstall
    '';
  };
in
stdenv.mkDerivation {
  pname = "bird-lsp";
  inherit version src;

  buildInputs = [
    typescript
  ];
  nativeBuildInputs = [
    nodejs
    pnpmConfigHook
    pnpm_10
    typescript
  ];

  pnpmDeps = fetchPnpmDeps {
    pname = "bird-lsp";
    inherit version src;
    fetcherVersion = 3;
    pnpm = pnpm_10;
    hash = "sha256-G6HmzS8cgmfcYyd5FbD1V6l5E+/eL/y6uA9x8yTGd7Q=";
  };

  postPatch = ''
    # Skip wasm compilation — we provide a pre-built wasm from Nix
    substituteInPlace packages/@birdcc/dprint-plugin-bird/package.json \
      --replace-fail \
        '"build": "node scripts/build-wasm.mjs && tsc -p tsconfig.json"' \
        '"build": "tsc -p tsconfig.json"'
  '';

  preBuild = ''
    # Place the pre-built wasm where the formatter package expects it
    mkdir -p packages/@birdcc/dprint-plugin-bird/dist
    cp ${dprintPluginBirdWasm}/dprint-plugin-bird.wasm \
      packages/@birdcc/dprint-plugin-bird/dist/dprint-plugin-bird.wasm
  '';

  buildPhase = ''
    runHook preBuild

    pnpm --filter=@birdcc/cli... build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    cp -r dist $out

    runHook postInstall
  '';

  meta = {
    description = "Modern Language Server Protocol support for BIRD2 configuration files";
    homepage = "https://github.com/bird-chinese-community/BIRD-LSP";
    license = lib.licenses.gpl3;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "bird-lsp";
  };
}
