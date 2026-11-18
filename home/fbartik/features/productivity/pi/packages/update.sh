#!/usr/bin/env bash
set -euo pipefail

# Usage: ./update.sh [package-name] (no argument updates all supported packages)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
REPO_ROOT=$(git rev-parse --show-toplevel)
FAKE_HASH='sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='

fail() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

nix_field() {
    awk -v key="$2" '$0 ~ "^[[:space:]]*" key "[[:space:]]*=[[:space:]]*\"" {
        split($0, fields, "\""); print fields[2]; exit
    }' "$1"
}

set_nix_field() {
    local file="$1" key="$2" value="$3"
    awk -v key="$key" -v value="$value" '
        $0 ~ "^[[:space:]]*" key "[[:space:]]*=[[:space:]]*\"" {
            sub(/"[^"]*"/, "\"" value "\""); count++
        }
        { print }
        END { if (count != 1) exit 1 }
    ' "$file" > "$file.tmp" || fail "Expected exactly one $key assignment in $(basename "$file")"
    mv "$file.tmp" "$file"
}

build_npm_deps() {
    # Evaluate the staged module directly: it may not be enabled on any host.
    # Use the repo's pinned nixpkgs and real overlay, including its lockfile
    # patches and npmDepsFetcherVersion, rather than prefetch-npm-deps defaults.
    PI_UPDATE_ROOT="$REPO_ROOT" PI_UPDATE_FILE="$1" nix build --impure --no-link --expr '
      let
        flake = builtins.getFlake (builtins.getEnv "PI_UPDATE_ROOT");
        overlays = import (flake.outPath + "/overlays") { inherit (flake) inputs; };
        pkgs = import flake.inputs.nixpkgs {
          system = builtins.currentSystem;
          overlays = [ overlays.modifications ];
        };
        module = import (/. + builtins.getEnv "PI_UPDATE_FILE") { inherit pkgs; };
        package = builtins.head module.programs.pi-coding-agent.settings.packages;
      in package.npmDeps
    '
}

update_package() (
    local file="$1" kind="$2" pname version url rev='' unpack=() lock=''
    local tmpdir staged prefetch src_hash output deps_hash
    pname=$(nix_field "$file" pname)
    [[ -n "$pname" ]] || fail "No pname in $file"
    tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT
    staged="$tmpdir/${file##*/}"
    cp "$file" "$staged"

    if [[ "$kind" == github ]]; then
        local owner repo tag tag_ref
        owner=$(nix_field "$file" owner)
        repo=$(nix_field "$file" repo)
        [[ -n "$owner" && -n "$repo" ]] || fail "No GitHub owner/repo in $file"
        local api="https://api.github.com/repos/$owner/$repo"
        tag=$(curl -fsSL "$api/releases/latest" | jq -er '.tag_name | strings | select(length > 0)')
        tag_ref=$(jq -rn --arg tag "$tag" '"refs/tags/\($tag)" | @uri')
        # The commits endpoint resolves both lightweight and annotated tags.
        rev=$(curl -fsSL "$api/commits/$tag_ref" | jq -er '.sha | strings | select(test("^[a-f0-9]{40}$"))')
        version="${tag#v}"
        url="https://github.com/$owner/$repo/archive/$rev.tar.gz"
        unpack=(--unpack)
    else
        local npm_name npm_url release
        lock="locks/${file##*/}"
        lock="${lock%.nix}.json"
        if [[ -f "$lock" ]]; then
            npm_name=$(jq -er '.name | strings | select(length > 0)' "$lock")
        else
            npm_url=$(nix_field "$file" url)
            [[ "$npm_url" == https://registry.npmjs.org/*/-/* ]] || fail "No npm registry URL in $file"
            npm_name="${npm_url#https://registry.npmjs.org/}"
            npm_name="${npm_name%/-/*}"
            lock=''
        fi
        release=$(curl -fsSL "https://registry.npmjs.org/$npm_name/latest")
        version=$(jq -er '.version | strings | select(length > 0)' <<< "$release")
        url=$(jq -er '.dist.tarball | strings | select(startswith("https://"))' <<< "$release")
        if [[ "$kind" == fetchzip ]]; then
            unpack=(--unpack)
        fi
    fi

    printf 'Updating %s: %s -> %s\n' "$pname" "$(nix_field "$file" version)" "$version"
    # The fixed-output hash is recursive for fetchzip/fetchFromGitHub, but
    # flat for fetchurl. --print-path keeps the hash and store path on stdout.
    prefetch=$(nix-prefetch-url --type sha256 --print-path ${unpack[@]+"${unpack[@]}"} "$url")
    src_hash=$(nix hash convert --hash-algo sha256 --to sri "${prefetch%%$'\n'*}")
    set_nix_field "$staged" version "$version"
    set_nix_field "$staged" hash "$src_hash"
    if [[ -n "$rev" ]]; then
        set_nix_field "$staged" rev "$rev"
    fi

    if [[ -n "$lock" ]]; then
        local src_path="${prefetch##*$'\n'}" work="$tmpdir/npm"
        # Use the same manifest and npm flags as the package's prePatch/build.
        mkdir -p "$work" "$tmpdir/locks"
        if [[ "$kind" == fetchurl ]]; then
            tar -xzf "$src_path" --strip-components=1 -C "$work" package/package.json
        else
            cp "$src_path/package.json" "$work/package.json"
        fi
        jq 'del(.devDependencies)' "$work/package.json" > "$work/manifest.json"
        mv "$work/manifest.json" "$work/package.json"
        cp "$lock" "$work/package-lock.json"
        (
            cd "$work"
            nix shell --inputs-from "$REPO_ROOT" "nixpkgs#${PI_UPDATE_NODEJS:-nodejs_24}" -c \
                npm install --package-lock-only --ignore-scripts --omit=dev --omit=peer --legacy-peer-deps
        )
        cp "$work/package-lock.json" "$tmpdir/$lock"
    fi

    if [[ -n "$(nix_field "$staged" npmDepsHash)" ]]; then
        # Probe only this package's npm-deps derivation. Reject mismatches
        # for its source or other inputs instead of taking the first `got:`.
        set_nix_field "$staged" npmDepsHash "$FAKE_HASH"
        if output=$(build_npm_deps "$staged" 2>&1); then
            fail "Expected an npmDepsHash mismatch for $pname, but the build succeeded"
        fi
        deps_hash=$(awk -v name="-$pname-$version-npm-deps.drv" -v fake="$FAKE_HASH" '
            /hash mismatch in fixed-output derivation/ { target = index($0, name); probe = 0 }
            target && $1 == "specified:" { probe = ($2 == fake) }
            target && probe && $1 == "got:" && $2 ~ /^sha256-[A-Za-z0-9+\/]+=*$/ { print $2; exit }
        ' <<< "$output")
        if [[ -z "$deps_hash" ]]; then
            printf '%s\n' "$output" >&2
            fail "Could not determine npmDepsHash for $pname"
        fi
        printf '  npmDepsHash: %s\n' "$deps_hash"
        set_nix_field "$staged" npmDepsHash "$deps_hash"
        build_npm_deps "$staged"
    fi

    # Do not publish new pins or a lockfile until all of the above succeeds.
    local changed=0
    if [[ -n "$lock" ]] && ! cmp -s "$lock" "$tmpdir/$lock"; then
        cp "$tmpdir/$lock" "$lock"
        changed=1
    fi
    if ! cmp -s "$file" "$staged"; then
        cp "$staged" "$file"
        changed=1
    fi
    if [[ "$changed" == 1 ]]; then
        printf '  Updated %s\n' "$pname"
    else
        printf '  Already up to date\n'
    fi
)

if [[ $# -gt 1 ]]; then
    fail "Usage: $0 [package-name]"
fi
selection="${1:-}"
matched=0
for file in ./*.nix; do
    name="${file##*/}"
    [[ -z "$selection" || "$name" == "$selection.nix" ]] || continue
    if grep -q 'src = pkgs.fetchFromGitHub' "$file"; then
        update_package "$file" github
    elif grep -q 'src = pkgs.fetchzip' "$file"; then
        update_package "$file" fetchzip
    elif grep -q 'src = pkgs.fetchurl' "$file"; then
        update_package "$file" fetchurl
    else
        continue
    fi
    matched=1
done
[[ "$matched" == 1 ]] || fail "No supported package found${selection:+: $selection}"
