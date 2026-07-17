#!/usr/bin/env bash
set -euo pipefail
export NIX_SSHOPTS="-A"

hostname="$1"

colmena apply --on "$hostname"
