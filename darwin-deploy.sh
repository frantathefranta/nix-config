#!/usr/bin/env bash
export NIX_SSHOPTS="-A"

# build_remote=false

if [[ "$1" == *.* ]]; then
    hostname=$(echo $1 | sed 's/\..*$//')
    fqdn="$1"
else
    hostname="$1"
    fqdn="$1"
fi

nix run github:nix-community/nh -- os switch .  --hostname $hostname --target-host $hostname.infra.franta.us --elevation-program passwordless
