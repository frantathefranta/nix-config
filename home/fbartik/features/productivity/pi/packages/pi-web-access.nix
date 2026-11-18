{
  pkgs,
  ...
}: let
  piWebAccess = pkgs.buildPiPackage {
    pname = "pi-web-access";
    version = "0.48.0";
    src = pkgs.fetchFromGitHub {
      owner = "nicobailon";
      repo = "pi-web-access";
      rev = "896d75bec55e316726db287a870eb166c4e3f40c";
      hash = "sha256-kvxwqQzvUEvBU8URxTCe4hGbWiUa41TbsdtdiM6+GqE=";
    };
    npmDepsHash = "sha256-6H9htKfObygFn6ZUOz6NwzsSXdSSYCXlkZYSc1Mq4oM=";
  };
in {
  programs.pi-coding-agent.settings.packages = [piWebAccess];
}
