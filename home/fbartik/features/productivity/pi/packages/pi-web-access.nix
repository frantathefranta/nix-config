{
  pkgs,
  ...
}: let
  piWebAccess = pkgs.buildPiPackage {
    pname = "pi-web-access";
    version = "0.37.0";
    src = pkgs.fetchFromGitHub {
      owner = "nicobailon";
      repo = "pi-web-access";
      rev = "ca30f5d00a9f587cd30d1ca044ef4cdcdc59bdea";
      hash = "sha256-iD8q2t6OdbVmV7BKaKn8EhNqCeMnv25WyZNuVOEI9bw=";
    };
    npmDepsHash = "sha256-RXW3ymqoqq6AnYqmfhgPrMhwB/6jYmaFQdT196vKvf4=";
  };
in {
  programs.pi-coding-agent.settings.packages = [piWebAccess];
}
