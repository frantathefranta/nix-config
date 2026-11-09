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
    default = true;
    type = lib.types.bool;
    description = ''
      Reboot the host after a deployment when `comin status` reports a
      reboot is needed (e.g. kernel update), like
      `system.autoUpgrade.allowReboot`.
    '';
  };

  config.services.comin = {
    enable = lib.mkDefault true;
    postDeploymentCommand = lib.mkIf cfg.autoReboot rebootScript;
    package = inputs.comin.packages.${pkgs.stdenv.hostPlatform.system}.comin;
    executor.type = "nix";
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