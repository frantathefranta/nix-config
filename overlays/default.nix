# This file defines overlays
{ inputs, ... }:
{
  # For every flake input, aliases 'pkgs.inputs.${flake}' to
  # 'inputs.${flake}.packages.${pkgs.system}' or
  # 'inputs.${flake}.legacyPackages.${pkgs.system}'
  flake-inputs = final: _: {
    inputs = builtins.mapAttrs (
      _: flake:
      let
        legacyPackages = (flake.legacyPackages or { }).${final.stdenv.hostPlatform.system} or { };
        packages = (flake.packages or { }).${final.stdenv.hostPlatform.system} or { };
      in
      if legacyPackages != { } then legacyPackages else packages
    ) inputs;
  };
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: prev: import ../pkgs { pkgs = final; };

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });
    # Taken from https://github.com/Misterio77/Foundry/blob/4b90ba3974faae2748c005900f37aaf81a5e16f6/overlays/default.nix#L166
    buildPiPackage =
      let
        inherit (final)
          lib
          buildNpmPackage
          fetchNpmDeps
          jq
          curl
          openssl
          cacert
          stdenvNoCC
          ;
        commonDefaults = {
          pname = "pi-extension";
          version = "unstable";
          installPhase = ''
            mkdir -p $out
            cp -r . $out/
          '';
        };
        # Some pi deps ship without a lockfile integrity field
        # (https://github.com/earendil-works/pi/issues/5653). A single shared
        # placeholder integrity makes every such dep collide on one npm cache
        # entry, so a fetch race decides the winner and the FOD is
        # non-deterministic. Instead fetch each dep's real registry integrity. This
        # runs only inside the FOD, where network is available, and is
        # deterministic because prefetch-npm-deps verifies every tarball against it.
        fetchRealIntegrity = ''
          for url in $(${lib.getExe jq} -r '[.. | objects | select(has("resolved") and (has("integrity") | not)) | .resolved] | unique | .[]' package-lock.json); do
            tarball="$(mktemp)"
            # Download to a file (not a pipe) so a failed fetch aborts the build
            # instead of silently yielding an empty digest; time out and retry so a
            # stalled connection can't hang the build forever.
            ${lib.getExe curl} -sSL --fail --connect-timeout 15 --max-time 300 \
              --retry 5 --retry-all-errors --retry-delay 2 \
              --cacert "${cacert}/etc/ssl/certs/ca-bundle.crt" -o "$tarball" "$url"
            integrity="sha512-$(${lib.getExe openssl} dgst -sha512 -binary "$tarball" | base64 -w0)"
            rm -f "$tarball"
            ${lib.getExe jq} --arg url "$url" --arg integrity "$integrity" \
              '(.. | objects | select(.resolved? == $url and (has("integrity") | not))) |= (. + {integrity: $integrity})' \
              package-lock.json > fixed-package-lock.json
            mv fixed-package-lock.json package-lock.json
          done
        '';
        npmDefaults = commonDefaults // {
          npmInstallFlags = [ "--omit=dev" ];
          npmDepsFetcherVersion = 2;
          dontNpmBuild = true;
        };
      in
      args:
      if args.dontNpmInstall or false then
        stdenvNoCC.mkDerivation (commonDefaults // args)
      else if args ? npmDeps then
        buildNpmPackage (npmDefaults // args)
      else
        let
          npmDeps = fetchNpmDeps {
            inherit (args) src;
            name = "${args.pname or commonDefaults.pname}-${args.version or commonDefaults.version}-npm-deps";
            hash = args.npmDepsHash;
            fetcherVersion = 2;
            nativeBuildInputs = [
              jq
              curl
              openssl
            ];
            # Run any package-specific prePatch (e.g. vendoring a lockfile)
            # before backfilling integrity for deps that still lack it.
            prePatch = (args.prePatch or "") + "\n" + fetchRealIntegrity;
          };
        in
        buildNpmPackage (
          npmDefaults
          // (builtins.removeAttrs args [ "npmDepsHash" ])
          // {
            inherit npmDeps;
            # The main build has no network, so reuse the integrity-patched
            # lockfile the FOD already produced; npmConfigHook requires it to
            # match ${npmDeps}/package-lock.json exactly, and to stay writable
            # for its own --fixup-lockfile pass.
            postPatch = ''
              rm -f package-lock.json
              cp ${npmDeps}/package-lock.json package-lock.json
              chmod u+w package-lock.json
            ''
            + (args.postPatch or "");
          }
        );
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  };

}
