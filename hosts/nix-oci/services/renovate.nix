{
  config,
  pkgs,
  ...
}:

{
  services.renovate = {
    enable = true;
    credentials = {
      RENOVATE_TOKEN = config.sops.secrets."renovate/token".path;
      RENOVATE_GITHUB_COM_TOKEN = config.sops.secrets."renovate/GITHUB_TOKEN".path;
    };
    package = pkgs.unstable.renovate;
    settings = {
      platform = "forgejo";
      endpoint = "https://codeberg.org";
      gitAuthor = "Lord of Lighting [bot] <lol@franta.us>";
      autodiscover = true;
    };
    schedule = "*:0/10";
  };
  sops.secrets = {
    "renovate/token".sopsFile = ../secrets.yaml;
    "renovate/GITHUB_TOKEN".sopsFile = ../secrets.yaml;
  };
}
