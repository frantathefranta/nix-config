set quiet
set script-interpreter := ['bash', '-euo', 'pipefail']
set shell := ['bash', '-euo', 'pipefail', '-c']

[private]
default:
    just -l

deploy host:
    scripts/deploy.sh {{ host }}

deploy-darwin host:
    scripts/darwin-deploy.sh {{ host }}

add-host-key ssh-host hostname:
    scripts/add-host-key.sh {{ ssh-host }} {{ hostname }}

list-settings setting:
    nix eval --json .#nixosConfigurations --apply 'cfgs: builtins.mapAttrs (_: cfg: cfg.config.{{ setting }}) cfgs' | jq . 

# Resolve only this stack's credentials for the lifetime of the tofu command.
[positional-arguments]
tofu stack +args:
    #!/usr/bin/env bash
    set -euo pipefail
    case "$1" in
        garage|uptimekuma) ;;
        *) echo "error: unknown Terraform stack: $1 (expected garage or uptimekuma)" >&2; exit 1 ;;
    esac
    stack="$1"
    shift
    exec op run --env-file="terraform/$stack/.env.1password" -- tofu -chdir="terraform/$stack" "$@"

update-dns:
    nix build .#octodns && op run --env-file=.1password -- octodns-sync --config=./result

update-dns-doit:
    nix build .#octodns && op run --env-file=.1password -- octodns-sync --config=./result --doit

update-pi-packages:
    cd home/fbartik/features/productivity/pi/packages && ./update.sh
