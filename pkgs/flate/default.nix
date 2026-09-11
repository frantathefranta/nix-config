{
  lib,
  buildGo127Module,
  fetchFromGitHub,
  git,
  nix-update-script,
}:

buildGo127Module (finalAttrs: {
  pname = "flate";
  version = "0.6.5";
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "home-operations";
    repo = "flate";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Z1bhf54xJSrCiLgRfzGuZ7ORzLgdFe5PfEVZzs8hkew=";
  };

  vendorHash = "sha256-6ZmGkdHW2/8wk/dKN9MkB+JF0/GFIw2TxZHeWShLsQ0=";

  ldflags = [
    "-s"
    "-w"
    "-X=main.version=${finalAttrs.version}"
  ];

  # The build sandbox sets HOME=/homeless-shelter (read-only); Go's
  # os.UserCacheDir() derives the cache root from it, so tests need a
  # writable home. git is required by pkg/source/git tests.
  nativeCheckInputs = [ git ];
  # test/e2e is excluded: a vendored cgo dependency passes -lresolv
  # unconditionally, which does not link on macOS (upstream bug).
  excludedPackages = [ "test/e2e" ];
  env.HOME = "$TMPDIR/home";

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "A Flux resource validator and inflator";
    homepage = "https://github.com/home-operations/flate";
    changelog = "https://github.com/home-operations/flate/blob/${finalAttrs.src.rev}/CHANGELOG.md";
    license = lib.licenses.agpl3Only;
    maintainers = with lib.maintainers; [ frantathefranta ];
    mainProgram = "flate";
  };
})
