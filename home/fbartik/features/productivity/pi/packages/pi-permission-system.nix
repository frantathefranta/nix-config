{ pkgs, ... }:
let
  version = "36.2.1";
  piPermissionSystem = pkgs.buildPiPackage {
    pname = "pi-permission-system";
    inherit version;
    src = pkgs.fetchzip {
      url = "https://registry.npmjs.org/@gotgenes/pi-permission-system/-/pi-permission-system-${version}.tgz";
      hash = "sha256-LGtYudebcoqZT6Fw9im7D6RTfjfu/uhoLfGXd8zTPx4=";
    };
    prePatch = ''
      ${pkgs.lib.getExe pkgs.jq} 'del(.devDependencies)' package.json > package.json.tmp
      mv package.json.tmp package.json
      cp ${./locks/pi-permission-system.json} package-lock.json
    '';
    npmInstallFlags = [
      "--omit=dev"
      "--omit=peer"
      "--legacy-peer-deps"
    ];
    npmDepsHash = "sha256-nFTUJq7QjrQwsqpxEXLAWFuIfNYeSkjcbR/W8P0xZLo=";
  };
in
{
  programs.pi-coding-agent.settings.packages = [ piPermissionSystem ];

  # Pattern maps use last-match-wins: keep catch-alls before specific rules.
  home.file.".pi/agent/extensions/pi-permission-system/config.json".source = ../permissions.json;
}
