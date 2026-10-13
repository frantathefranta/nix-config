{
  lib,
  fetchFromGitHub,
  fetchPnpmDeps,
  nodejs,
  pnpm_11,
  pnpmConfigHook,
  typescript,
  stdenv,
  rustPlatform,
  lld,
  makeWrapper,
}:
let
  version = "0.1.1";

  src = fetchFromGitHub {
    owner = "bird-chinese-community";
    repo = "BIRD-LSP";
    tag = "v${version}";
    hash = "sha256-GvEO9Ps7CcKZKrQRvOHZ6vbOLOcbfCaHeUef6UXkM5w=";
  };

  # Build the dprint BIRD formatter plugin as wasm32-unknown-unknown.
  # Use the host rustPlatform (no pkgsCross) and simply override CARGO_BUILD_TARGET.
  # This avoids pkgsCross trying to build rustc from source with WASI SDK etc.
  # Requires nixpkgs' rustc to include the wasm32-unknown-unknown stdlib.
  dprintPluginBirdWasm = rustPlatform.buildRustPackage {
    pname = "dprint-plugin-bird-wasm";
    version = "0.0.1";

    src = "${src}/packages/@birdcc/dprint-plugin-bird";

    cargoLock = {
      lockFile = ./Cargo.lock;
    };

    nativeBuildInputs = [ lld ];
    doCheck = false;

    buildPhase = ''
      runHook preBuild
      cargo build --release --target wasm32-unknown-unknown --features wasm
      runHook postBuild
    '';

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

  __structuredAttrs = true;

  strictDeps = true;

  buildInputs = [
    typescript
  ];
  nativeBuildInputs = [
    nodejs
    pnpmConfigHook
    pnpm_11
    typescript
    makeWrapper
  ];

  pnpmDeps = fetchPnpmDeps {
    pname = "bird-lsp";
    inherit version src;
    fetcherVersion = 4;
    pnpm = pnpm_11;
    hash = "sha256-cCKT+PTseWaWiiFKQPxnQRGjLwef6+sejhZG7uVi06k=";
  };

  postPatch = ''
    # pnpm 11 no longer reads link-workspace-packages from upstream's .npmrc.
    # Keep local dependencies in the workspace graph for filtering and build order.
    echo 'linkWorkspacePackages: true' >> pnpm-workspace.yaml

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

    pnpm --recursive --filter=@birdcc/cli... build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,lib/birdcc}
    cp -r {packages,node_modules} $out/lib/birdcc

    makeWrapper ${nodejs}/bin/node $out/bin/birdcc \
      --add-flags "$out/lib/birdcc/packages/@birdcc/cli/dist/cli.js"

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    "$out/bin/birdcc" --help > /dev/null
    printf 'router id 192.0.2.1;\nprotocol device {}\n' > smoke.conf
    "$out/bin/birdcc" lint smoke.conf

    # Test dprint directly so a fallback to the builtin formatter cannot hide failure.
    node --input-type=module <<EOF
    import { formatBirdConfig } from "file://$out/lib/birdcc/packages/@birdcc/formatter/dist/index.js";
    await formatBirdConfig("router id 192.0.2.1;\\nprotocol device {}\\n", { engine: "dprint" });
    EOF

    runHook postInstallCheck
  '';

  meta = {
    description = "Modern Language Server Protocol support for BIRD2 configuration files";
    homepage = "https://github.com/bird-chinese-community/BIRD-LSP";
    license = lib.licenses.gpl3;
    maintainers = with lib.maintainers; [ frantathefranta ];
    mainProgram = "birdcc";
  };
}
