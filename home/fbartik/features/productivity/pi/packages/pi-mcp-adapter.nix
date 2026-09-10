{
  pkgs,
  ...
}: let
  piMcpAdapter = pkgs.buildPiPackage {
    pname = "pi-mcp-adapter";
    version = "2.32.1";
    src = pkgs.fetchFromGitHub {
      owner = "nicobailon";
      repo = "pi-mcp-adapter";
      rev = "10a45367e033a32026987a75d6f401e37340c86f";
      hash = "sha256-/NrC8cVEdhswKEQcuVugNSOCGJ3/c6k2Qg8o6hg0X14=";
    };
    npmDepsHash = "sha256-dOdYmNJI8oXHMFJTxIlmGsIhpNcSuXrrSkT/u3LmhhM=";
  };
in {
  programs.pi-coding-agent.settings.packages = [piMcpAdapter];
}