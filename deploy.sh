#!/usr/bin/env bash
export NIX_SSHOPTS="-A"

build_remote=false

if [[ "$1" == *.* ]]; then
    hostname=$(echo $1 | sed 's/\..*$//')
    fqdn="$1"
else
    hostname="$1"
    fqdn="$1"
fi

# if [ -z "$1" ]; then
#     echo "No hosts to deploy"
#     exit 2
# fi

# for host in ${hosts//,/ }; do
    nh os switch .\#nixosConfigurations.$hostname --target-host $fqdn --ask
# done
