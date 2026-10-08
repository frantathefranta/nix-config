{ pkgs, ... }:
let
  version = "0.7.1";
  piSandbox = pkgs.buildPiPackage {
    pname = "pi-sandbox";
    inherit version;
    src = pkgs.fetchzip {
      url = "https://registry.npmjs.org/pi-sandbox/-/pi-sandbox-${version}.tgz";
      hash = "sha256-pERmbl7TJJpzvi3VZE58zbfQPCjo7hAQWW+zSSTGMOA=";
    };
    prePatch = ''
      ${pkgs.lib.getExe pkgs.jq} 'del(.devDependencies)' package.json > package.json.tmp
      mv package.json.tmp package.json
      cp ${./locks/pi-sandbox.json} package-lock.json
    '';
    npmInstallFlags = [
      "--omit=dev"
      "--omit=peer"
      "--legacy-peer-deps"
    ];
    npmDepsHash = "sha256-tgTAd8OrWpm0woHstAcbK1HYJMA1mcfPVjuUobqcCAI=";
  };
in
{
  programs.pi-coding-agent = {
    settings.packages = [ piSandbox ];
    extraPackages = [
      pkgs.ripgrep
    ]
    ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
      pkgs.bubblewrap
      pkgs.socat
    ];
  };

  # Global policy is declarative; save interactive grants to the project or session.
  home.file.".pi/agent/sandbox.json".source = ../sandbox.json;
}
