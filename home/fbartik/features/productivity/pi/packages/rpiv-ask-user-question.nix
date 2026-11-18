{ pkgs, ... }:
let
  version = "2.15.0";
  rpivAskUserQuestion = pkgs.buildPiPackage {
    pname = "rpiv-ask-user-question";
    inherit version;
    src = pkgs.fetchzip {
      url = "https://registry.npmjs.org/@juicesharp/rpiv-ask-user-question/-/rpiv-ask-user-question-${version}.tgz";
      hash = "sha256-bHq4BM1Iib60+ta2Zrjnih445KUddAXNfGJwKRKOx1Q=";
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
    npmDepsHash = "sha256-+rsnAg8a4pkbod+DY5JjyL5LkW+nmybX/AjUJFIO2PI=";
  };
in
{
  programs.pi-coding-agent.settings.packages = [ rpivAskUserQuestion ];
}
