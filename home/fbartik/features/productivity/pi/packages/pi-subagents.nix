{
  pkgs,
  ...
}: let
  pisubAgents = pkgs.buildPiPackage {
    pname = "pi-subagents";
    version = "0.89.0";
    src = pkgs.fetchFromGitHub {
      owner = "nicobailon";
      repo = "pi-subagents";
      rev = "4aa4ddb0ecb7ad56a6c9e56c96f39f7877a1550f";
      hash = "sha256-DTe0j9JQfsXD3O9eeu/Tz7cnvsdM2bjtn63wqHYphu8=";
    };
    npmDepsHash = "sha256-McLpOJ6UOsEtT265xG/iK7MafoieV5cPL6hYWWj+Z8k=";
  };
in {
  programs.pi-coding-agent.settings.packages = [pisubAgents];
}
