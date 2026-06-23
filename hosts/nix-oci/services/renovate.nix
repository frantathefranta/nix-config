{
  config,
  pkgs,
  ...
}:

{
  environment.systemPackages = [ pkgs.opentofu ];

  services.renovate = {
    enable = true;
    credentials = {
      RENOVATE_TOKEN = config.sops.secrets."renovate/token".path;
      RENOVATE_GITHUB_COM_TOKEN = config.sops.secrets."renovate/GITHUB_TOKEN".path;
    };
    package = pkgs.unstable.renovate;
    environment = {
      LOG_LEVEL = "debug";
    };
    settings = {
      platform = "forgejo";
      endpoint = "https://git.franta.us";
      gitAuthor = "Lord of Lighting [bot] <lol@franta.us>";
      autodiscover = true;
      allowedCommands = [ "^/run/current-system/sw/bin/nix flake lock$" ];
    };
    schedule = "*:0/10";
  };
  sops.secrets = {
    "renovate/token".sopsFile = ../secrets.yaml;
    "renovate/GITHUB_TOKEN".sopsFile = ../secrets.yaml;
  };
}
