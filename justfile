set quiet
set script-interpreter := ['bash', '-euo', 'pipefail']
set shell := ['bash', '-euo', 'pipefail', '-c']

[private]
default:
    just -l

list-settings setting:
    nix eval --json .#nixosConfigurations --apply 'cfgs: builtins.mapAttrs (_: cfg: cfg.config.{{ setting }}) cfgs' | jq . 

update-dns:
    nix build .#octodns && octodns-sync --config=./result

update-dns-doit:
    nix build .#octodns && octodns-sync --config=./result --doit
