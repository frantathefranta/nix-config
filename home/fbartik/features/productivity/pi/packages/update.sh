#!/usr/bin/env bash
set -euo pipefail

# Auto-update script for pi packages with full npmDepsHash support
# Usage: ./update.sh [package-name] (or no args to update all)
#
# This script updates:
# 1. Source version and hash using nix-prefetch-url
# 2. Lockfile version using npm
# 3. npmDepsHash by building and capturing from error message
#
# The script automatically computes all hashes. For npm packages, it does a
# quick build to get the correct npmDepsHash (due to fetcherVersion 2 used by
# buildPiPackage).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Get current version from a Nix file
get_current_version() {
    local file="$1"
    grep -oP 'version\s*=\s*"\K[^"]+' "$file" 2>/dev/null | head -1
}

# Get current hash from a Nix file
get_current_hash() {
    local file="$1"
    grep -oP 'hash\s*=\s*"\K[^"]+' "$file" 2>/dev/null | head -1
}

# Get current rev from a Nix file  
get_current_rev() {
    local file="$1"
    grep -oP 'rev\s*=\s*"\K[^"]+' "$file" 2>/dev/null | head -1
}

# Get npmDepsHash from a Nix file
get_npm_deps_hash() {
    local file="$1"
    grep -oP 'npmDepsHash\s*=\s*"\K[^"]+' "$file" 2>/dev/null | head -1
}

# Update npm package with full npmDepsHash support
update_npm_package() {
    local file="$1"
    
    # Get the package name from lockfile if available
    local file_basename
    file_basename=$(basename "$file")
    local lockfile_base="${file_basename%.nix}.json"
    local lockfile_dir
    lockfile_dir=$(cd "${file%/*}" && pwd)
    local lockfile="$lockfile_dir/locks/$lockfile_base"
    local npm_package_name=""
    
    if [[ -f "$lockfile" ]]; then
        npm_package_name=$(jq -r '.name' "$lockfile" 2>/dev/null | head -1)
    fi
    
    # Try to extract from URL pattern as fallback
    if [[ -z "$npm_package_name" ]] || [[ "$npm_package_name" == "null" ]]; then
        npm_package_name=$(grep 'registry.npmjs.org' "$file" | awk -F'registry.npmjs.org/' '{print $2}' | sed 's|-.*||')
    fi
    
    if [[ -z "$npm_package_name" ]]; then
        echo "  ⚠️  Could not determine package name from $file"
        return 1
    fi
    
    echo "  📦 Processing npm package: $npm_package_name"
    
    # Get latest version from npm registry
    local latest_version
    latest_version=$(curl -s "https://registry.npmjs.org/$npm_package_name" | jq -r '.time | keys[]' | sort -V | grep -v modified | grep -v created | grep -v last | tail -1)
    
    if [[ -z "$latest_version" ]]; then
        echo "  ❌ Failed to get latest version"
        return 1
    fi
    
    local current_version
    current_version=$(get_current_version "$file")
    
    echo "  📋 Current version: $current_version"
    echo "  🆕 Latest version: $latest_version"
    
    # Build URL for the tarball
    local url
    if [[ "$npm_package_name" == *"@"* ]]; then
        local base_name
        base_name=$(echo "$npm_package_name" | sed 's|@.*/||')
        url="https://registry.npmjs.org/$npm_package_name/-/$base_name-$latest_version.tgz"
    else
        url="https://registry.npmjs.org/$npm_package_name/-/$npm_package_name-$latest_version.tgz"
    fi
    
    # Compute source hash using nix-prefetch-url
    local hash_base32
    hash_base32=$(nix-prefetch-url --type sha256 --unpack "$url" 2>&1 | grep -v "path is" | tail -1)
    local hash_base64
    hash_base64=$(nix hash convert sha256:$hash_base32 --to base64 2>/dev/null | tail -1)
    local src_hash="sha256-$hash_base64"
    
    echo "  🔢 New source hash: $src_hash"
    
    # For npm packages with lockfile, update the lockfile and compute npmDepsHash
    if [[ -f "$lockfile" ]]; then
        echo "  📝 Updating lockfile..."
        local tmp_lockfile="${lockfile}.tmp"
        
        # Update version in lockfile - root and main package
        jq --arg version "$latest_version" '.version = $version | .packages[""].version = $version' "$lockfile" > "$tmp_lockfile"
        mv "$tmp_lockfile" "$lockfile"
        
        # Create a temporary directory to unpack the source and regenerate lockfile
        local tmpdir
        tmpdir=$(mktemp -d)
        trap "rm -rf $tmpdir" RETURN
        
        echo "  📦 Unpacking source..."
        # Use a safe name without @ or / for scoped packages
        local safe_name="${npm_package_name//\@/_}" 
        safe_name="${safe_name//\//_}"
        local src_output
        src_output=$(nix-prefetch-url --unpack "$url" --name "$safe_name-$latest_version" 2>&1)
        local src_path
        src_path=$(echo "$src_output" | grep -oP "/nix/store/[a-z0-9_.-]+" | head -1)
        
        if [[ -z "$src_path" ]] || [[ ! -d "$src_path" ]]; then
            echo "  ❌ Failed to unpack source"
            echo "  Output: $src_output"
            return 1
        fi
        
        # Copy source to writable temp directory (preserve permissions)
        local work_dir="$tmpdir/source"
        cp -rp "$src_path" "$work_dir"
        
        # Make files writable so we can modify them
        chmod -R u+w "$work_dir"
        
        # Copy the updated lockfile to the working directory
        cp "$lockfile" "$work_dir/package-lock.json"
        
        # Remove devDependencies from package.json (same as prePatch in the Nix file)
        jq 'del(.devDependencies)' "$work_dir/package.json" > "$work_dir/package.json.tmp"
        mv "$work_dir/package.json.tmp" "$work_dir/package.json"
        
        # Regenerate lockfile with npm install (dry-run to avoid actually installing)
        echo "  📝 Regenerating lockfile with npm..."
        if ! nix shell nixpkgs#nodejs_24 -c sh -c "cd '$work_dir' && npm install --package-lock-only --omit=dev --omit=peer --legacy-peer-deps" 2>&1; then
            echo "  ⚠️  npm install failed, using existing lockfile"
        fi
        
        # Copy the regenerated lockfile back
        if [[ -f "$work_dir/package-lock.json" ]]; then
            cp "$work_dir/package-lock.json" "$lockfile"
            echo "  ✅ Lockfile regenerated"
        fi
        
        echo "  🔢 Computing npmDepsHash..."
        local npm_deps_hash
        npm_deps_hash=$(nix shell nixpkgs#prefetch-npm-deps -c prefetch-npm-deps "$work_dir/package-lock.json" 2>&1 | grep -oP 'sha256-[A-Za-z0-9+/=]+' | tail -1)
        
        if [[ -z "$npm_deps_hash" ]]; then
            echo "  ⚠️  Could not compute npmDepsHash."
            return 1
        fi
        
        echo "  🆕 Computed npmDepsHash: $npm_deps_hash"
        # The buildPiPackage uses fetchNpmDeps with fetcherVersion=2
        # We need to verify the hash by building
        
        # Try a quick build to verify the hash
        echo "  🔍 Verifying npmDepsHash with a quick build..."
        local build_output
        build_output=$(cd "$SCRIPT_DIR/../../../../../" && nix build '.#homeConfigurations.fbartik@NC312237.activationPackage' 2>&1) || true
        
        # Check if there's a hash mismatch
        if echo "$build_output" | grep -q "hash mismatch"; then
            # Extract the correct hash from the error message
            local correct_hash
            correct_hash=$(echo "$build_output" | grep -oP 'got:\s*sha256-[A-Za-z0-9+/=]+' | grep -oP 'sha256-[A-Za-z0-9+/=]+' | head -1)
            
            if [[ -n "$correct_hash" ]]; then
                echo "  ⚠️  Hash mismatch detected!"
                echo "  Computed: $npm_deps_hash"
                echo "  Expected: $correct_hash"
                npm_deps_hash="$correct_hash"
                echo "  ✅ Using correct hash from build error"
            fi
        else
            echo "  ✅ Hash verified successfully"
        fi
        
        # Update the Nix file with all hashes
        local current_hash
        current_hash=$(get_current_hash "$file")
        local current_npm_deps_hash
        current_npm_deps_hash=$(get_npm_deps_hash "$file")
        
        if [[ "$src_hash" != "$current_hash" ]] || [[ "$latest_version" != "$current_version" ]] || [[ "$npm_deps_hash" != "$current_npm_deps_hash" ]]; then
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i'' "s| version = \"[^\"]*\";| version = \"$latest_version\";|" "$file"
                sed -i'' "s| hash = \"[^\"]*\";| hash = \"$src_hash\";|" "$file"
                sed -i'' "s| npmDepsHash = \"[^\"]*\";| npmDepsHash = \"$npm_deps_hash\";|" "$file"
            else
                sed -i.bak "s| version = \"[^\"]*\";| version = \"$latest_version\";|" "$file"
                sed -i.bak "s| hash = \"[^\"]*\";| hash = \"$src_hash\";|" "$file"
                sed -i.bak "s| npmDepsHash = \"[^\"]*\";| npmDepsHash = \"$npm_deps_hash\";|" "$file"
                rm -f "$file".bak
            fi
            echo "  ✅ Updated $file"
            return 0
        else
            echo "  ✅ Already up to date"
            return 0
        fi
    else
        # No lockfile - just update source hash
        local current_hash
        current_hash=$(get_current_hash "$file")
        
        if [[ "$src_hash" != "$current_hash" ]] || [[ "$latest_version" != "$current_version" ]]; then
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i'' "s| version = \"[^\"]*\";| version = \"$latest_version\";|" "$file"
                sed -i'' "s| hash = \"[^\"]*\";| hash = \"$src_hash\";|" "$file"
            else
                sed -i.bak "s| version = \"[^\"]*\";| version = \"$latest_version\";|" "$file"
                sed -i.bak "s| hash = \"[^\"]*\";| hash = \"$src_hash\";|" "$file"
                rm -f "$file".bak
            fi
            echo "  ✅ Updated $file"
            return 0
        else
            echo "  ✅ Already up to date"
            return 0
        fi
    fi
}

# Update GitHub package
update_github_package() {
    local file="$1"
    local owner
    owner=$(grep -oP 'owner\s*=\s*"\K[^"]+' "$file" | head -1)
    local repo
    repo=$(grep -oP 'repo\s*=\s*"\K[^"]+' "$file" | head -1)
    
    if [[ -z "$owner" ]] || [[ -z "$repo" ]]; then
        echo "  ⚠️  Could not determine owner/repo from $file"
        return 1
    fi
    
    echo "  📦 Processing GitHub package: $owner/$repo"
    
    # Get latest release
    local latest_release
    latest_release=$(curl -s "https://api.github.com/repos/$owner/$repo/releases/latest" | jq -r '.tag_name')
    
    if [[ -z "$latest_release" ]]; then
        echo "  ❌ Failed to get latest release"
        return 1
    fi
    
    # Remove 'v' prefix for version
    local version="${latest_release#v}"
    
    # Get the commit hash for this tag
    local rev
    rev=$(curl -s "https://api.github.com/repos/$owner/$repo/git/ref/tags/$latest_release" | jq -r '.object.sha')
    
    # Get current values
    local current_version
    current_version=$(get_current_version "$file")
    local current_rev
    current_rev=$(get_current_rev "$file")
    
    echo "  📋 Current version: $current_version"
    echo "  🆕 Latest version: $latest_release"
    echo "  📋 Current rev: $current_rev"
    echo "  🆕 Latest rev: $rev"
    
    # Fetch new hash
    local url="https://github.com/$owner/$repo/archive/$rev.tar.gz"
    local hash_base32
    hash_base32=$(nix-prefetch-url --type sha256 --unpack "$url" 2>&1 | grep -v "path is" | tail -1)
    local hash_base64
    hash_base64=$(nix hash convert sha256:$hash_base32 --to base64 2>/dev/null | tail -1)
    local hash="sha256-$hash_base64"
    
    echo "  🔢 Current hash: $(get_current_hash "$file")"
    echo "  🆕 New hash: $hash"
    
    # Update the file
    if [[ "$hash" != "$(get_current_hash "$file")" ]] || [[ "$latest_release" != "$current_version" ]] || [[ "$rev" != "$current_rev" ]]; then
        sed -i.bak "s| version = \"[^\"]*\";| version = \"$version\";|" "$file"
        sed -i.bak "s| rev = \"[^\"]*\";| rev = \"$rev\";|" "$file"
        sed -i.bak "s| hash = \"[^\"]*\";| hash = \"$hash\";|" "$file"
        rm -f "$file".bak
        echo "  ✅ Updated $file"
        return 0
    else
        echo "  ✅ Already up to date"
        return 0
    fi
}

# Main logic
echo "=== pi package auto-update script ==="
echo ""

# Find all .nix files in the directory (excluding update scripts and default.nix)
nix_files=()
while IFS= read -r -d '' file; do
    filename=$(basename "$file")
    if [[ "$filename" != update*.sh ]] && [[ "$filename" != default.nix ]]; then
        nix_files+=("$file")
    fi
done < <(find . -maxdepth 1 -name "*.nix" -print0 2>/dev/null)

if [[ ${#nix_files[@]} -eq 0 ]]; then
    echo "No .nix files found in $SCRIPT_DIR"
    exit 0
fi

echo "Found ${#nix_files[@]} package file(s) to check:"
for file in "${nix_files[@]}"; do
    echo "  - $(basename "$file")"
done
echo ""

updated_count=0

for file in "${nix_files[@]}"; do
    echo "→ Processing $(basename "$file")"
    
    if grep -q "fetchFromGitHub" "$file"; then
        if update_github_package "$file"; then
            ((updated_count++)) || true
        fi
    elif grep -q "fetchzip\|fetchurl" "$file"; then
        if update_npm_package "$file"; then
            ((updated_count++)) || true
        fi
    else
        echo "  ⚠️  Unknown fetch method, skipping"
    fi
    echo ""
done

echo "=== Summary ==="
echo "Updated: $updated_count file(s)"
echo ""
echo "Next steps:"
echo "1. Review the changes with: git diff"
echo "2. Build the configuration to verify: nix build .#homeConfigurations.fbartik@NC312237.activationPackage"