{
  pkgs,
  ...
}: let
  pisubAgents = pkgs.buildPiPackage {
    pname = "pi-subagents";
    version = "0.53.0";
    src = pkgs.fetchFromGitHub {
      owner = "nicobailon";
      repo = "pi-subagents";
      rev = "a2d4452ffe647d1a0a0b765d86327d42dcd839c6";
      hash = "sha256-WSsCgt/ZyG8KUaB7s0EBtOgdgEkqE+3bgRjOZhpHKbA=";
    };
    npmDepsHash = "sha256-/7e301fFT7CcSnN3PWqjp4TBtO3oi1OY0Cb/8xEc6s0=";
  };
in {
  programs.pi-coding-agent.settings.packages = [pisubAgents];
}
