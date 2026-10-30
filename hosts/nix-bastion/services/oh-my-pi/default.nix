{
  inputs,
  pkgs,
  config,
  ...
}:
let
  inherit (import ../container-addresses.nix) omp;
in
{
  # The shared daemon authenticates by host UID. Reserve a non-wheel identity
  # so the container user does not inherit fbartik's trusted Nix access.
  users.groups.omp.gid = 1100;
  users.users.omp = {
    isSystemUser = true;
    uid = 1100;
    group = "omp";
  };

  containers.omp = {
    autoStart = true;
    privateNetwork = true;
    # NixOS creates peer /32 and /128 routes. No bridge, NAT or proxy NDP.
    hostAddress = omp.hostIPv4;
    localAddress = omp.localIPv4;
    hostAddress6 = omp.hostIPv6;
    localAddress6 = omp.localIPv6;

    config = {
      networking = {
        useHostResolvConf = false;
        defaultGateway = omp.hostIPv4;
        defaultGateway6 = {
          address = omp.hostIPv6;
          interface = "eth0";
        };
        nameservers = config.systemd.network.networks."10-ens18".dns;
        firewall.trustedInterfaces = [ "eth0" ];
      };
      services.openssh.enable = true;

      # Only OMP beyond the NixOS base tools and Nix. No host user configuration,
      # Home Manager, secrets or additional host filesystem mounts.
      environment.systemPackages = [
        inputs.oh-my-pi.packages.${pkgs.stdenv.hostPlatform.system}.omp
        pkgs.python3
        pkgs.unstable.paseo
      ];
      users.groups.omp.gid = 1100;
      users.users.fbartik = {
        isNormalUser = true;
        uid = 1100;
        group = "omp";
      };

      # nixos-container supplies the read-only host store and daemon socket;
      # NixOS sets NIX_REMOTE=daemon inside containers. Builds run on the host.
      nix = {
        settings.experimental-features = [
          "nix-command"
          "flakes"
        ];
        registry.nixpkgs.flake = inputs.nixpkgs;
        nixPath = [ "nixpkgs=flake:nixpkgs" ];
      };

      system.stateVersion = "26.05";
    };
  };
  networking.firewall.allowedTCPPorts = [ 6767 ];
}
