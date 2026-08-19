{
  pkgs,
  ...
}: let
  piWebAccess = pkgs.buildPiPackage {
    pname = "pi-web-access";
    version = "0.24.0";
    src = pkgs.fetchFromGitHub {
      owner = "nicobailon";
      repo = "pi-web-access";
      rev = "ebb0c447530a425fb7f14d4b78fd4b221e7d917a";
      hash = "sha256-1E6ogt3gL+UhuLaTiLYlcDgjKar9AP3izuDEk1erXlI=";
    };
    npmDepsHash = "sha256-db4DqtCAnoWYte/KEvvujr5wXx1rVDu/tdyGq6v/zk8=";
  };
in {
  programs.pi-coding-agent.settings.packages = [piWebAccess];
}
