{
  pkgs,
  ...
}: let
  piMcpAdapter = pkgs.buildPiPackage {
    pname = "pi-mcp-adapter";
    version = "2.34.0";
    src = pkgs.fetchFromGitHub {
      owner = "nicobailon";
      repo = "pi-mcp-adapter";
      rev = "ccf0e3e69f5b96adcb99a7bcdc38e0dd4581c71a";
      hash = "sha256-YpiJROIG0/U81wAoImjktbg/d5wGnc6o130IlOrTyEE=";
    };
    npmDepsHash = "sha256-ZxrUJXi/seXm4OhAqbVdJO77J/VhDSRtEFFS5KN8pZA=";
  };
in {
  programs.pi-coding-agent.settings.packages = [piMcpAdapter];
}
