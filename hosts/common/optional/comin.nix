{ config, inputs, pkgs, lib, ... }:
let
  cfg = config.services.comin;
  rebootScript = pkgs.writeShellScript "comin-reboot-if-needed" ''
    if ${config.services.comin.package}/bin/comin status | ${pkgs.ripgrep}/bin/rg -q 'Need to reboot: yes'; then
      sleep 5
      ${pkgs.systemd}/bin/systemctl reboot
    fi
  '';
in
{
  imports = [ inputs.comin.nixosModules.comin ];

  options.services.comin.autoReboot = lib.mkOption {
    default = false;
    type = lib.types.bool;
    description = ''
      Reboot the host after a successful deployment when
      `comin status` reports a reboot is needed (e.g. kernel update),
      like `system.autoUpgrade.allowReboot`.
    '';
  };

  services.comin = {
    enable = lib.mkDefault true;
    autoReboot = lib.mkDefault false;
    postDeploymentCommand = lib.mkIf cfg.autoReboot rebootScript;
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
    exporter.openFirewall = true;
  };
}
