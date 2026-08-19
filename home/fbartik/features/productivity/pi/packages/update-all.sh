#!/usr/bin/env bash
set -euo pipefail

# Auto-update script for pi packages in a directory
# It scans for .nix files in the current directory and updates versions/hashes
# Usage: ./update-all.sh [package-name] (or no args to update all)

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

# Update npm package
update_npm_package() {
    local file="$1"
    
    # Get the package name from lockfile if available
    local npm_package_name
    local lockfile="${file%/*}/locks/${file%.nix}.json"
    if [[ -f "$lockfile" ]]; then
        npm_package_name=$(jq -r '.name' "$lockfile" 2>/dev/null | head -1)
        if [[ -n "$npm_package_name" ]] && [[ "$npm_package_name" != "null" ]]; then
            echo "  📋 Package name from lockfile: $npm_package_name"
        fi
    fi
    
    # Try to extract from URL pattern as fallback
    if [[ -z "$npm_package_name" ]] || [[ "$npm_package_name" == "null" ]]; then
        local url_pkg_name
        url_pkg_name=$(grep 'registry.npmjs.org' "$file" | awk -F'registry.npmjs.org/' '{print $2}' | sed 's|-.*||')
        if [[ -n "$url_pkg_name" ]]; then
            npm_package_name="$url_pkg_name"
        else
            echo "  ⚠️  Could not determine package name from $file"
            return 1
        fi
    fi
    
    echo "  📦 Processing npm package: $npm_package_name"
    
    # Get latest version from npm registry
    local latest_version
    latest_version=$(curl -s "https://registry.npmjs.org/$npm_package_name" | jq -r '.time | keys[]' | sort -V | grep -v modified | grep -v created | grep -v last | tail -1)
    
    if [[ -z "$latest_version" ]]; then
        echo "  ❌ Failed to get latest version"
        return 1
    fi
    
    # Get current version
    local current_version
    current_version=$(get_current_version "$file")
    
    echo "  📋 Current version: $current_version"
    echo "  🆕 Latest version: $latest_version"
    
    # For fetchzip, we need to compute the hash of the unpacked contents
    # We'll use nix-prefetch-url which is available in the nixpkgs channel
    local url
    if [[ "$npm_package_name" == *"@"* ]]; then
        # Scoped package like @juicesharp/rpiv-ask-user-question
        # Extract the base name for the tarball filename
        local base_name
        base_name=$(echo "$npm_package_name" | sed 's|@.*/||')
        url="https://registry.npmjs.org/$npm_package_name/-/$base_name-$latest_version.tgz"
    else
        # Non-scoped package
        url="https://registry.npmjs.org/$npm_package_name/-/$npm_package_name-$latest_version.tgz"
    fi
    
    # Compute hash using nix-prefetch-url with --unpack flag
    # nix-prefetch-url with --unpack computes the hash of the unpacked contents
    local hash_base32
    hash_base32=$(nix-prefetch-url --type sha256 --unpack "$url" 2>&1 | grep -v "path is" | tail -1)
    
    # Convert base32 to base64 (SRI format for sha256)
    local hash_base64
    hash_base64=$(nix hash convert sha256:$hash_base32 --to base64 2>/dev/null | tail -1)
    
    # Add sha256- prefix for SRI format
    local hash="sha256-$hash_base64"
    
    if [[ -z "$hash" ]] || [[ "$hash" == "sha256-" ]]; then
        echo "  ⚠️  Could not compute hash automatically. Please update manually."
        return 1
    fi
    
    echo "  🔢 Current hash: $(get_current_hash "$file")"
    echo "  🆕 New hash: $hash"
    
    # Update the file
    if [[ "$hash" != "$(get_current_hash "$file")" ]] || [[ "$latest_version" != "$current_version" ]]; then
        sed -i.bak "s| version = \"[^\"]*\";| version = \"$latest_version\";|" "$file"
        sed -i.bak "s| hash = \"[^\"]*\";| hash = \"$hash\";|" "$file"
        rm -f "$file".bak
        echo "  ✅ Updated $file"
        return 0
    else
        echo "  ✅ Already up to date"
        return 0
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
    
    # Fetch new hash using nix-prefetch-url with --unpack to get the hash of unpacked contents
    local url="https://github.com/$owner/$repo/archive/$rev.tar.gz"
    local hash_base32
    hash_base32=$(nix-prefetch-url --type sha256 --unpack "$url" 2>&1 | grep -v "path is" | tail -1)
    
    # Convert base32 to base64 (SRI format for sha256)
    local hash_base64
    hash_base64=$(nix hash convert sha256:$hash_base32 --to base64 2>/dev/null | tail -1)
    
    # Add sha256- prefix for SRI format
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
    # Skip update scripts and default.nix
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
skipped_count=0

for file in "${nix_files[@]}"; do
    echo "→ Processing $(basename "$file")"
    
    # Determine if it's an npm or GitHub package
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
        ((skipped_count++)) || true
    fi
    echo ""
done

echo "=== Summary ==="
echo "Updated: $updated_count file(s)"
echo "Skipped: $skipped_count file(s)"
echo ""
echo "Don't forget to check the lockfile if it exists!"