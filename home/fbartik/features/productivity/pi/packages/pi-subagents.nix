{
  pkgs,
  ...
}: let
  pisubAgents = pkgs.buildPiPackage {
    pname = "pi-subagents";
    version = "0.68.0";
    src = pkgs.fetchFromGitHub {
      owner = "nicobailon";
      repo = "pi-subagents";
      rev = "2b27f93aec462814cff952218d2b34bc01572f84";
      hash = "sha256-YamJDmW49sKG1FUhGcJZobeKZSWD/hWjHiSvi1kur54=";
    };
    npmDepsHash = "sha256-gxLZe3++sp8ru311gqtHs5g/Uzy23fKuvczDYxf1mgk=";
  };
in {
  programs.pi-coding-agent.settings.packages = [pisubAgents];
}
