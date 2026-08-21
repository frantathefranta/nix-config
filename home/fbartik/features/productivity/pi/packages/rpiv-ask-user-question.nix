{ pkgs, ... }:
let
  version = "2.6.4";
  rpivAskUserQuestion = pkgs.buildPiPackage {
    pname = "rpiv-ask-user-question";
    inherit version;
    src = pkgs.fetchzip {
      url = "https://registry.npmjs.org/@juicesharp/rpiv-ask-user-question/-/rpiv-ask-user-question-${version}.tgz";
      hash = "sha256-8WFGH7sA1+k6uJYFr+1flsNlpT9XPTKLoqwznGvoMJs=";
    };
    prePatch = ''
      ${pkgs.lib.getExe pkgs.jq} 'del(.devDependencies)' package.json > package.json.tmp
      mv package.json.tmp package.json
      cp ${./locks/rpiv-ask-user-question.json} package-lock.json
    '';
    npmInstallFlags = [
      "--omit=dev"
      "--omit=peer"
      "--legacy-peer-deps"
    ];
    npmDepsHash = "sha256-7wxcuLJ5LwG/WrRUaktpiRhfqneI+MjxRNUOWUQLYp0=";
  };
in
{
  programs.pi-coding-agent.settings.packages = [ rpivAskUserQuestion ];
}
