{
  config,
  pkgs,
  ...
}: let
  piWebAccess = pkgs.buildPiPackage {
    pname = "pi-web-access";
    version = "v0.24.0";
    src = pkgs.fetchFromGitHub {
      owner = "nicobailon";
      repo = "pi-web-access";
      rev = "3b875f574840eebae39e5fede0d99a5f7c71f482";
      hash = "sha256-1E6ogt3gL+UhuLaTiLYlcDgjKar9AP3izuDEk1erXlI=";
    };
    npmDepsHash = "sha256-db4DqtCAnoWYte/KEvvujr5wXx1rVDu/tdyGq6v/zk8=";
  };
in {
  programs.pi-coding-agent.settings.packages = [piWebAccess];
  home.file.".pi/agent/web-access.json".text = builtins.toJSON {
    kagiApiKey = "!cat ${config.home.homeDirectory}/.config/sops-nix/pi/kagi-api-key";
  };
}
