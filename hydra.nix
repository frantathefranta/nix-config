{
  inputs,
  outputs,
}: let
  inherit (inputs.nixpkgs) lib;

  notBroken = pkg: !(pkg.meta.broken or false);
  isDistributable = pkg: (pkg.meta.license or {redistributable = true;}).redistributable;
  hasPlatform = sys: pkg: lib.elem sys (pkg.meta.platforms or [sys]);
  filterValidPkgs = sys: pkgs:
    lib.filterAttrs (
      _: pkg: lib.isDerivation pkg && hasPlatform sys pkg && notBroken pkg && isDistributable pkg
    )
    pkgs;

  pkgsOut = lib.mapAttrs filterValidPkgs (lib.filterAttrs (sys: _: !(lib.hasSuffix "darwin" sys)) outputs.packages);
  hostsOut = lib.mapAttrs (_: cfg: cfg.config.system.build.toplevel) outputs.nixosConfigurations;
  homesOut =
    lib.mapAttrs (_: cfg: cfg.activationPackage)
    (lib.filterAttrs (_: cfg: !(lib.hasSuffix "darwin" cfg.pkgs.stdenv.system)) outputs.homeConfigurations);

  # A single job whose success implies every other job succeeded, so branch
  # protection / auto-merge has one stable status check to require instead
  # of needing to track every individual package/host/home job by name.
  aggregatePkgs = import inputs.nixpkgs {system = "x86_64-linux";};
in {
  pkgs = pkgsOut;
  hosts = hostsOut;
  homes = homesOut;
  required = aggregatePkgs.releaseTools.aggregate {
    name = "required";
    constituents =
      lib.concatMap lib.attrValues (lib.attrValues pkgsOut)
      ++ lib.attrValues hostsOut
      ++ lib.attrValues homesOut;
  };
}
