# Remove when https://github.com/maralorn/nix-output-monitor/pull/321 lands in nixpkgs.
# Determinate Nix emits activity types that older nom versions do not recognize.
final: prev: {
  nix-output-monitor = prev.nix-output-monitor.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ./patches/handle-unknown-activity-types.patch
    ];
  });

  # nh wraps its PATH; point that wrapper at the patched nom as well.
  nh = prev.nh.override {
    inherit (final) nix-output-monitor;
  };
}
