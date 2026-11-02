# Hydra input resolution

Legacy substitution records can label sibling outputs as `out`, including
[Fish's `doc` output](https://hydra.infra.franta.us/build/16396/step/207) and
[nixos-render-docs' `dist` output](https://hydra.infra.franta.us/build/15828/step/8).
The Rust queue runner's database-first resolution can then select the sibling
instead of the executable output. The required path remains in `nativeBuildInputs`
but is absent from the sandbox, producing `build input ... does not exist` even
when `nix-store --check-validity` succeeds on the host.

Hydrogen's `services.hydra.queueRunner.package` applies
[`patches/static-output-paths.patch`](patches/static-output-paths.patch), vendored from
[Hydra PR #1988](https://github.com/NixOS/hydra/pull/1988) at head
`4d1d7010a1088df4bde0bf439d71938d843d3661`. For direct dependency outputs,
it prefers known `.drv` paths over recorded paths and logs mismatches.
Dynamic dependency chains retain upstream's recursive SQL resolution.
The PR is not yet merged; remove this backport when the pinned Hydra includes
the upstream fix. Historical records do not need to be rewritten.

Activate the patched queue runner on Hydrogen before restarting failed host
builds in Hydra. If Hydrogen's own job cannot finish, bootstrap the change
manually using the [server recovery procedure](../../../../README.md#initial-rollout-and-recovery);
keep comin stopped until `main` contains the fix so it cannot restore the old
queue runner. Hydra's **Restart** action clears the affected failed-path cache;
reevaluation alone does not.
