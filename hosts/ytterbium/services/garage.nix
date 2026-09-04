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
        root_domain = ".s3.garage.localhost";
      };
      s3_web = {
        bind_addr = "[::]:3902";
        root_domain = ".web.garage.localhost";
        index = "index.html";
      };
      admin = {
        api_bind_addr = "[::]:3903";
      };
    };
  };
  # nixpkgs default is just "garage server", this skips manually assigning role
  # Might be fixed in the future: https://github.com/NixOS/nixpkgs/pull/537352
  systemd.services.garage.serviceConfig.ExecStart =
    lib.mkForce "${config.services.garage.package}/bin/garage server --single-node";
  networking.firewall.allowedTCPPorts = [
    3900
    3902
    3903
  ];
  sops.secrets."garage/env".sopsFile = ../secrets.yaml;
}
