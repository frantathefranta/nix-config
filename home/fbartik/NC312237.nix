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
    ./features/productivity/pi
    ./features/productivity/github.nix
    ./features/productivity/forgejo.nix
    ./features/productivity/nix/nix-init.nix
  ];
  home.packages = with pkgs; [
    symbola
    # nix.enable is false on Darwin (see nixpkgs.nix), so pkgs.nix itself
    # isn't installed. Pull in just its "man" output for nix*/nix.conf man pages
    # without putting a nixpkgs `nix` binary on PATH ahead of Determinate's.
    nix.man
    # d2

    #work
    openvox # Puppet
    puppet-lint
    r10k
    bundler
  ];
  programs.nh = {
    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = "--keep-since 14d";
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
        hostName = "hydrogen.infra.franta.us";
        protocol = "ssh-ng";
        systems = [ "x86_64-linux" "aarch64-linux" ];
        sshUser = "fbartik";
        sshKey = "/etc/ssh/ssh_host_ed25519_key";
      }
      {
        hostName = "nix-oci.cloud.franta.us";
        protocol = "ssh-ng";
        systems = [ "aarch64-linux" ];
        speedFactor = 2;
        sshUser = "admin";
        sshKey = "/etc/ssh/ssh_host_ed25519_key";
      }
    ];
  };
  # TODO: Consider adding https://github.com/DivitMittal/hammerspoon-nix

  programs.fish.functions.puppet_dev = /* fish */ ''
    # Run the OSC puppet-dev container with the current directory mounted as /work
    function puppet_dev --description 'Run the OSC puppet-dev container against the current directory'
      if test (count $argv) -eq 0
        echo "puppet_dev needs a command to execute"
        return
      end

      if not command -q podman
        echo "podman must be in PATH"
        return
      end

      podman run --rm -it --pull always \
        -u puppet --userns keep-id:uid=52,gid=52 \
        -v $HOME/.ssh:/home/puppet/.ssh \
        -v $HOME/.gitconfig:/home/puppet/.gitconfig:ro \
        -v (pwd):/work \
        -w /work \
        -e DEBUG \
        docker-registry.osc.edu/osc/puppet-dev:latest $argv
    end
  '';

  nixpkgs.overlays = [ inputs.emacs-tramp-rpc.overlays.default ];

}
