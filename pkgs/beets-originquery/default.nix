{
  lib,
  fetchFromGitHub,
  buildPythonPackage,
  setuptools,

  # dependencies
  beets,
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

  dependencies = [
    beets
    confuse
    jsonpath-rw
    pyyaml
  ];

  # Plugin has no tests
  doCheck = false;

  meta = {
    description = "Beets plugin that improves album matching by reading origin metadata files";
    homepage = "https://github.com/frantathefranta/beets-originquery";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ];
    platforms = lib.platforms.all;
  };
}
