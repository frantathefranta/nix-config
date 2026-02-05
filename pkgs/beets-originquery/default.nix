{
  lib,
  fetchFromGitHub,
  buildPythonPackage,
  setuptools,

  # dependencies
  confuse,
  jsonpath-rw,
  pyyaml,
}:

buildPythonPackage rec {
  pname = "beets-originquery";
  version = "1.0.2-unstable-2025-12-10";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "frantathefranta";
    repo = "beets-originquery";
    rev = "866800ae571ed73d9fd4f562131985e3c7ca1fc8";
    hash = "sha256-XQdRbxwJghYJiuYA5GhTyxe5RfWrd+8nUPtVWlAYKVY=";
  };

  build-system = [ setuptools ];

  # Note: beets is not included here to avoid duplicate derivations
  # when the plugin is used with beets.override { pluginOverrides = ... }
  dependencies = [
    confuse
    jsonpath-rw
    pyyaml
  ];

  # Plugin has no tests
  doCheck = false;

  # Disable runtime dependency check since beets is provided by the parent package
  dontCheckRuntimeDeps = true;

  meta = {
    description = "Beets plugin that improves album matching by reading origin metadata files";
    homepage = "https://github.com/frantathefranta/beets-originquery";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ];
    platforms = lib.platforms.all;
  };
}
