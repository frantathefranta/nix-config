{
  config,
  lib,
  ...
}:
let
  mkBuildMachine =
    {
      uri ? null,
      systems ? null,
      sshKey ? null,
      maxJobs ? 1,
      speedFactor ? 1,
      supportedFeatures ? null,
      mandatoryFeatures ? null,
      publicHostKey ? null,
    }:
    let
      field =
        x:
        if (x == null || x == [ ] || x == "") then
          "-"
        else if (builtins.isInt x) then
          (builtins.toString x)
        else if (builtins.isList x) then
          (builtins.concatStringsSep "," x)
        else
          x;
    in
    ''
      ${field uri} ${field systems} ${field sshKey} ${field maxJobs} ${field speedFactor} ${field supportedFeatures} ${field mandatoryFeatures} ${field publicHostKey}
    '';
  mkBuildMachines =
    machines: builtins.toFile "machines" (lib.concatStringsSep "\n" (map mkBuildMachine machines));
in
{
  services.hydra.buildMachinesFiles = [
    (mkBuildMachines [
      {
        uri = "ssh://nix-ssh@nix-oci.infra.franta.us";
        systems = [
          "aarch64-linux"
        ];
        sshKey = config.sops.secrets."hydra/nix-ssh-key".path;
        maxJobs = 1;
        supportedFeatures = [
          "kvm"
          "big-parallel"
          "nixos-test"
        ];
      }
      {
        uri = "localhost";
        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "i686-linux"
        ];
        maxJobs = 1;
        supportedFeatures = [
          "kvm"
          "big-parallel"
          "nixos-test"
        ];
      }
    ])
  ];
}
