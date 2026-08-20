{
  pkgs,
  ...
}: let
  pisubAgents = pkgs.buildPiPackage {
    pname = "pi-subagents";
    version = "0.51.0";
    src = pkgs.fetchFromGitHub {
      owner = "nicobailon";
      repo = "pi-subagents";
      rev = "10f69cdfd1ec384a3d6079b136b88970d79ec09a";
      hash = "sha256-jCvTUW6u7eHb1+2/qtjGAID5WkxXhjYA4k1HohOCIRQ=";
    };
    npmDepsHash = "sha256-g9Da56i6YcYZPqR4QUjqG7AFDM5ktYXuns0YknotyPM=";
  };
in {
  programs.pi-coding-agent.settings.packages = [pisubAgents];
}
