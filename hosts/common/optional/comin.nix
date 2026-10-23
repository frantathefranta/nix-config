{ config, inputs, pkgs, lib, ... }:
{
  imports = [ inputs.comin.nixosModules.comin ];

  services.comin = {
    enable = lib.mkDefault true;
    package = inputs.comin.packages.${pkgs.stdenv.hostPlatform.system}.comin;
    executor = {
      type = "hydra";
      hydra = {
        base_url = "https://hydra.infra.franta.us";
        project = "nix-home";
        job_name = "hosts.${config.networking.hostName}";
      };
    };
    remotes = [
      {
        name = "origin";
        url = "https://git.franta.us/franta/nix-home.git";
        branches.main.name = "main";
      }
    ];
  };
}
