{
  pkgs,
  ...
}: let
  piWebAccess = pkgs.buildPiPackage {
    pname = "pi-web-access";
    version = "0.29.0";
    src = pkgs.fetchFromGitHub {
      owner = "nicobailon";
      repo = "pi-web-access";
      rev = "a99c1903365cc3115787df82e115524fcb55d85f";
      hash = "sha256-5YMwE44pyMmCapGt9kFLxT61Qg3OCzuJCIATRhMBv6M=";
    };
    npmDepsHash = "sha256-0ScX5nMu3h8/KCysaeNiXj/DK7E3abY8LINAaAARhCc=";
  };
in {
  programs.pi-coding-agent.settings.packages = [piWebAccess];
}
