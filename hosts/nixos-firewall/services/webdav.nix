{
  config,
  ...
}:

{
  services.webdav = {
    enable = true;
    settings = {
      address = "0.0.0.0";
      port = 8080;
      directory = "/srv/public";
      permissions = "R";
      users = [
        {
          username = "{env}ENV_USERNAME";
          password = "{env}ENV_PASSWORD";
        }
      ];
    };
    environmentFile = config.sops.secrets."webdav-env".path;
  };
  sops.secrets."webdav-env".sopsFile = ../secrets.yaml;
}
