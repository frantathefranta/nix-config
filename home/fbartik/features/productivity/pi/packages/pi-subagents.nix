{
  pkgs,
  ...
}: let
  pisubAgents = pkgs.buildPiPackage {
    pname = "pi-subagents";
    version = "0.76.1";
    src = pkgs.fetchFromGitHub {
      owner = "nicobailon";
      repo = "pi-subagents";
      rev = "47adea8646db031787f4988e8cfd8608d4d0ddf1";
      hash = "sha256-D+JOBUu/RsYMcG+Cj5my9LYXmzzq9bEP0fCbZEEKGLI=";
    };
    npmDepsHash = "sha256-2duDXmscVGiDVydmRUseOHxUdcfOagZiGfG81m0QxUM=";
  };
in {
  programs.pi-coding-agent.settings.packages = [pisubAgents];
}
