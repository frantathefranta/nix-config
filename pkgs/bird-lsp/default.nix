{
  lib,
  fetchFromGitHub,
  fetchPnpmDeps,
  nodejs,
  pnpm_10,
  pnpmConfigHook,
  typescript,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "bird-lsp";
  version = "0.0.1-0";

  src = fetchFromGitHub {
    owner = "bird-chinese-community";
    repo = "BIRD-LSP";
    tag = "v${finalAttrs.version}";
    hash = "sha256-DrA+Olc++aRJkFTytxONN7kR+baOnw/7yKyET2s87fU=";
  };

  buildInputs = [
    typescript
  ];
  nativeBuildInputs = [
    nodejs # in case scripts are run outside of a pnpm call
    pnpmConfigHook
    pnpm_10 # At least required by pnpmConfigHook, if not other (custom) phases
    typescript
  ];

  pnpmWorkspaces = [ "@birdcc/lsp" ];
  pnpmDeps = fetchPnpmDeps {
    # inherit (finalAttrs) pname version src;
    inherit (finalAttrs) pnpmWorkspaces pname version src;
    fetcherVersion = 3;
    pnpm = pnpm_10;
    hash = "sha256-G6HmzS8cgmfcYyd5FbD1V6l5E+/eL/y6uA9x8yTGd7Q=";
  };
  buildPhase = ''
    runHook preBuild

    pnpm -r --filter=@birdcc/lsp... --parallel build
    # pnpm --filter='!intel' --filter='!vscode' --filter='!dprint-plugin-bird' build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    cp -r dist $out

    runHook postInstall
  '';
  # buildPhase = ''
  #   runHook preBuild

  #   pnpm --filter='!vscode' --filter='!dprint-plugin-bird' build

  #   runHook postBuild
  # '';
  # --filter '!dprint-plugin-bird'" ];
  # outputs = [
  #   "out"
  # ];

  meta = {
    description = "Modern Language Server Protocol support for BIRD2 configuration files ";
    homepage = "https://github.com/bird-chinese-community/BIRD-LSP";
    license = lib.licenses.gpl3;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "bird-lsp";
  };
})
