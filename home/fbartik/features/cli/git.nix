{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:

let
  defaultKey =
    if osConfig != null && osConfig.networking.hostName == "silicium" then
      "6476C19999AA5FD0220F03CD899EEBE51E1C696A"
    else
      "2FDD0DA7EA2674718E42055E128750E77EF037D4";
in
{
  programs.git = {
    enable = true;
    package = pkgs.gitFull;
    settings = {
      user = {
        name = "Franta Bartik";
        email = "fb@franta.us";
      };
      init.defaultBranch = "main";
      # fish takes these options and adds them to the prompt
      bash = {
        showInformativeStatus = true;
        showDirtyState = true;
        showUntrackedFiles = true;
      };
      aliases = {
        p = "pull --ff-only";
        ff = "merge --ff-only";
        graph = "log --decorate --oneline --graph";
        pushall = "!git remote | xargs -L1 git push --all";
        add-nowhitespace = "!git diff -U0 -w --no-color | git apply --cached --ignore-whitespace --unidiff-zero -";
      };
      signing = {
        # commit.gpgSign = lib.mkDefault true;
        format = "openpgp";
        key = defaultKey;
      };
      gpg.program = "${config.programs.gpg.package}/bin/gpg2";

      merge.conflictStyle = "zdiff3";
      commit.verbose = true;
      diff.algorithm = "histogram";
      log.date = "iso";
      column.ui = "auto";
      branch.sort = "committerdate";
      # Automatically track remote branch
      push.autoSetupRemote = true;
      # Reuse merge conflict fixes when rebasing
      rerere.enabled = true;
    };
    lfs.enable = true;
    ignores = [
      ".claude"
      ".direnv"
      "result"
      ".jj"
      ".agent-shell"
    ];
  };
}
