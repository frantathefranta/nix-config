{pulls, ...}: let
  repoOwner = "franta";
  repoName = "nix-home";
  giteaHttpUrl = "https://git.franta.us";
  repoUrl = "${giteaHttpUrl}/${repoOwner}/${repoName}";

  prs = builtins.fromJSON (builtins.readFile pulls);

  # `flake` drives the actual build. The `inputs` below are redundant with
  # it (same repo/rev, fetched a second time as a plain git checkout) but
  # are required for the GiteaStatus plugin, which reads its target
  # owner/repo/revision from named jobset inputs on the eval -- it has no
  # visibility into a flake-type jobset's resolved flake ref.
  mkFlakeJobset = {
    flake,
    rev,
    description,
  }: {
    enabled = 1;
    hidden = false;
    inherit description flake;
    type = 1;
    checkinterval = 60;
    schedulingshares = 100;
    enableemail = false;
    emailoverride = "";
    keepnr = 1;
    inputs = {
      src = {
        type = "git";
        value = "${repoUrl}.git ${rev}";
        emailresponsible = false;
      };
      gitea_status_repo = {
        type = "string";
        value = "src";
        emailresponsible = false;
      };
      gitea_repo_owner = {
        type = "string";
        value = repoOwner;
        emailresponsible = false;
      };
      gitea_repo_name = {
        type = "string";
        value = repoName;
        emailresponsible = false;
      };
      gitea_http_url = {
        type = "string";
        value = giteaHttpUrl;
        emailresponsible = false;
      };
    };
  };

  mainJobset.main = mkFlakeJobset {
    flake = "git+${repoUrl}?ref=main";
    rev = "main";
    description = "main branch";
  };

  prJobsets = builtins.listToAttrs (map (number: let
    pr = prs.${number};
  in {
    name = "pr-${number}";
    value = mkFlakeJobset {
      flake = "git+${repoUrl}?rev=${pr.head.sha}";
      rev = pr.head.sha;
      description = "#${number}: ${pr.title}";
    };
  }) (builtins.attrNames prs));

  jobsetsJson = builtins.toJSON (mainJobset // prJobsets);
in {
  jobsets = derivation {
    name = "jobsets.json";
    system = builtins.currentSystem;
    builder = "/bin/sh";
    args = ["-c" ''printf '%s' "$jobsetsJson" > "$out"''];
    inherit jobsetsJson;
  };
}
