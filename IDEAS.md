# Ideas

## Cross-host WireGuard validation

Nix has no built-in symmetry checking for WireGuard tunnel configs, but two native
mechanisms could cover it:

### 1. Per-host `assertions`

Add assertions inside NixOS modules (can use `dn42Of` to access peer configs):

```nix
assertions = lib.mapAttrsToList (name: iface: {
  assertion = (dn42Of iface.peerHostname).ipv6Subnet != null;
  message = "ibgp peer ${iface.peerHostname} has no ipv6Subnet set";
}) (lib.filterAttrs (n: _: lib.hasPrefix "ibgp_" n)
     config.services.custom-wireguard.interfaces);
```

Good for catching null/missing values per-host. Cannot easily check cross-host
symmetry (e.g. that the other side's `peerAddressV6` matches your `localAddressV6`)
without more complex cross-referencing.

### 2. Flake-level `checks` output

`nix flake check` builds everything under `outputs.checks`. A derivation here can
evaluate both sides of every iBGP link and assert port/address symmetry.

The gap: both approaches require encoding the pairing invariants explicitly, since the
two sides of a link are not currently linked by a shared identifier — the relationship
is implicit.

### Prerequisite: explicit link identity

Add a shared `linkId` (or similar) attribute on both sides of each iBGP interface.
This makes pairing unambiguous and enables a flake-level check to:

- iterate all `ibgp_*` interfaces across all `nixosConfigurations`
- group by `linkId`
- assert that `localAddressV6` on one side matches `peerAddressV6` on the other
- assert listen ports match
