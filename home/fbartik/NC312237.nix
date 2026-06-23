{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./global
    ./features/editor
    ./features/kubectl
    ./features/desktop/common/mail.nix
    ./features/productivity/claude-code.nix
  ];
  home.packages = with pkgs; [
    symbola
    # nix.enable is false on Darwin (see nixpkgs.nix), so pkgs.nix itself
    # isn't installed. Pull in just its "man" output for nix*/nix.conf man pages
    # without putting a nixpkgs `nix` binary on PATH ahead of Determinate's.
    nix.man
    # d2
  ];
  programs.nh = {
    clean = {
      enable = true;
    };
    enable = true;
    homeFlake = "${config.home.homeDirectory}/git/nix-config";
    package = inputs.nh.packages.aarch64-darwin.nh;
  };
  sops.age.keyFile = "${config.home.homeDirectory}/Library/Application Support/sops/age/keys.txt";
  sops.defaultSopsFile = ./NC312237-secrets.yaml;

  # sops-nix doesn't know about age-plugin-yubikey, so it has to be added to the launchd's $PATH
  launchd.agents.sops-nix.config.EnvironmentVariables."PATH" =
    lib.mkForce "/usr/bin:/bin:/usr/sbin:/sbin:${pkgs.age-plugin-yubikey}/bin";

  # My state version is 24.11, which defaults to linkApps. Changing it to copyApps which allows Spotlight to index the apps
  targets.darwin.linkApps.enable = false;
  targets.darwin.copyApps.enable = true;

  nix = {
    distributedBuilds = true;
    buildMachines = [
      {
        # "hydrogen.infra.franta.us" = {
        hostName = "hydrogen.infra.franta.us";
        protocol = "ssh-ng";
        # mandatoryFeatures = [
        #   "kvm"
        #   "big-parallel"
        #   "nixos-test"
        # ];
        systems = [ "x86_64-linux" "aarch64-linux" ];
        sshUser = "fbartik";
        sshKey = "/etc/ssh/ssh_host_ed25519_key";
        # };
      }
    ];
  };
  # TODO: Consider adding https://github.com/DivitMittal/hammerspoon-nix

}
