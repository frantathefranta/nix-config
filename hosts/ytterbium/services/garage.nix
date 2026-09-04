{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.garage = {
    enable = true;
    package = pkgs.garage_2;
    environmentFile = config.sops.secrets."garage/env".path;
    settings = {
      data_dir = "/emc1/s3";
      rpc_bind_addr = "[::]:3901";
      db_engine = "sqlite";
      replication_factor = 1;
      s3_api = {
        api_bind_addr = "[::]:3900";
        s3_region = "garage";
        root_domain = ".s3.infra.franta.us";
      };
      s3_web = {
        bind_addr = "[::]:3902";
        root_domain = ".web.infra.franta.us";
        index = "index.html";
      };
      admin = {
        api_bind_addr = "[::]:3903";
      };
    };
  };
  # nixpkgs default is just "garage server", this skips manually assigning role
  # --default-bucket creates the terraform-state bucket (and its access key) on start
  # from the GARAGE_DEFAULT_* variables in the env file; see sops secret garage/env
  # Might be fixed in the future: https://github.com/NixOS/nixpkgs/pull/537352
  systemd.services.garage.serviceConfig.ExecStart =
    lib.mkForce "${config.services.garage.package}/bin/garage server --single-node --default-bucket";
  networking.firewall.allowedTCPPorts = [
    3900
    3902
    3903
  ];
  networking.domains.subDomains."s3.${config.networking.domain}".cname.data = config.networking.hostName;
  sops.secrets."garage/env".sopsFile = ../secrets.yaml;
}
