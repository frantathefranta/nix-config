{
  imports = [
    ../../common/optional/caddy.nix
    # These would be useful for persistence
    # ../../common/optional/mysql.nix
    # ../../common/optional/postgres.nix

    ./binary-cache.nix
    ./hydra
  ];
}
