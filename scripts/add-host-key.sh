#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: $(basename "$0") <ssh-host> <hostname>"
    echo ""
    echo "  ssh-host   nixos-anywhere target (e.g. root@1.2.3.4)"
    echo "  hostname   NixOS hostname — must already have a nixosConfigurations entry"
    echo ""
    echo "What this does:"
    echo "  1. Reuses existing keys from 1Password if present, otherwise generates a fresh ed25519 pair"
    echo "  2. Stores the private key in 1Password as a document: 'NixOS SSH Host Key: <hostname>'"
    echo "  3. Saves the public key to hosts/<hostname>/ssh_host_ed25519_key.pub"
    echo "  4. Derives the age key and wires it into .sops.yaml"
    echo "  5. Re-encrypts hosts/common/secrets.yaml with the new key"
    echo "  6. Deploys via nixos-anywhere, placing the key pair on the target"
    echo ""
    echo "Requires: ssh-keygen, ssh-to-age, sops, op, nixos-anywhere"
    exit 1
}

[[ $# -ne 2 ]] && usage

SSH_HOST="$1"
HOSTNAME="$2"

for cmd in ssh-to-age sops op nixos-anywhere; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "error: $cmd not found — ensure it is available before running" >&2
        exit 1
    fi
done

if [[ -z "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]]; then
    echo "error: OP_SERVICE_ACCOUNT_TOKEN is not set" >&2
    exit 1
fi

REPO_ROOT="$(git -C "$(dirname "$(realpath "$0")")" rev-parse --show-toplevel)"
HOST_PATH="$REPO_ROOT/hosts/$HOSTNAME"
PUB_KEY_FILE="$HOST_PATH/ssh_host_ed25519_key.pub"
SOPS_YAML="$REPO_ROOT/.sops.yaml"
COMMON_SECRETS="$REPO_ROOT/hosts/common/secrets.yaml"

mkdir -p "$HOST_PATH"

# --- 1. Prepare extra-files tree ---
EXTRA_FILES="$(mktemp -d)"
trap 'rm -rf "$EXTRA_FILES"' EXIT

SSH_DIR="$EXTRA_FILES/etc/ssh"
install -d -m755 "$EXTRA_FILES/etc"
install -d -m755 "$SSH_DIR"

PRIV_KEY="$SSH_DIR/ssh_host_ed25519_key"
PUB_KEY_TMP="$SSH_DIR/ssh_host_ed25519_key.pub"

OP_ITEM_TITLE="NixOS SSH Host Key: $HOSTNAME"

# --- 2. Retrieve existing key from 1Password, or generate and store a new one ---
# Use op document (binary attachment) rather than a text field so the private
# key bytes are preserved exactly — JSON string encoding corrupts PEM data.
if op document get "$OP_ITEM_TITLE" --vault "nix-config" --output "$PRIV_KEY" 2>/dev/null; then
    echo "==> Retrieved existing private key from 1Password ('$OP_ITEM_TITLE')"
    chmod 600 "$PRIV_KEY"
    # Derive the public key from the retrieved private key
    ssh-keygen -y -f "$PRIV_KEY" > "$PUB_KEY_TMP"
    chmod 644 "$PUB_KEY_TMP"
else
    echo "==> Generating ed25519 SSH host key pair..."
    ssh-keygen -t ed25519 -C "root@$HOSTNAME" -f "$PRIV_KEY" -N ""
    chmod 600 "$PRIV_KEY"
    chmod 644 "$PUB_KEY_TMP"
    echo "    Generated key: $(cat "$PUB_KEY_TMP")"

    echo "==> Saving private key to 1Password..."
    op document create "$PRIV_KEY" \
        --title "$OP_ITEM_TITLE" \
        --vault "nix-config" \
        --format json >/dev/null
    echo "    Created 1Password document: '$OP_ITEM_TITLE'"
fi

# --- 3. Save public key to repo ---
cp "$PUB_KEY_TMP" "$PUB_KEY_FILE"
echo "==> Saved public key to $PUB_KEY_FILE"

# --- 4. Derive age key and update .sops.yaml ---
echo "==> Deriving age key..."
AGE_KEY=$(ssh-to-age -i "$PUB_KEY_FILE")
echo "    Age key: $AGE_KEY"

echo "==> Updating .sops.yaml..."
python3 - "$SOPS_YAML" "$HOSTNAME" "$AGE_KEY" <<'PYEOF'
import sys
import re

sops_yaml = sys.argv[1]
hostname  = sys.argv[2]
age_key   = sys.argv[3]

with open(sops_yaml) as f:
    content = f.read()

# --- keys section: add or update &hostname anchor ---
anchor_pattern = re.compile(rf'^( *- &{re.escape(hostname)} )age1\S+', re.MULTILINE)
anchor_line    = f'    - &{hostname} {age_key}'

if anchor_pattern.search(content):
    content = anchor_pattern.sub(lambda m: m.group(1) + age_key, content)
    print(f'    Updated existing key for {hostname}')
else:
    insert_before = re.search(r'^    # age-plugin-yubikey', content, re.MULTILINE)
    if insert_before:
        pos = insert_before.start()
    else:
        insert_before = re.search(r'^    - &NC312237 ', content, re.MULTILINE)
        if insert_before:
            pos = insert_before.start()
        else:
            print('WARNING: could not find insertion point in keys section — add manually', file=sys.stderr)
            pos = None
    if pos is not None:
        content = content[:pos] + anchor_line + '\n' + content[pos:]
        print(f'    Added new key for {hostname}')

# --- creation_rules: add *hostname to common secrets age list ---
lines = content.splitlines(keepends=True)
in_common    = False
in_age       = False
last_age_idx = -1
inserted     = False

for i, line in enumerate(lines):
    if 'path_regex: hosts/common/secrets' in line:
        in_common = True
    elif in_common and re.match(r'\s+- age:\s*$', line):
        in_age = True
    elif in_common and in_age and re.match(r'\s+- \*\S', line):
        if f'*{hostname}' in line:
            print(f'    *{hostname} already present in common secrets rule')
            inserted = True
            break
        last_age_idx = i
    elif in_common and in_age and re.match(r'\s+pgp:', line):
        if not inserted and last_age_idx >= 0:
            ref_indent = re.match(r'(\s+)', lines[last_age_idx]).group(1)
            lines.insert(last_age_idx + 1, f'{ref_indent}- *{hostname}\n')
            print(f'    Added *{hostname} to common secrets rule')
        elif not inserted:
            print('WARNING: could not find age list in common secrets rule', file=sys.stderr)
        inserted = True
        break
    elif in_common and 'path_regex:' in line and 'common' not in line:
        break

with open(sops_yaml, 'w') as f:
    f.write(''.join(lines))
PYEOF

# --- 5. Re-encrypt common secrets ---
echo "==> Re-encrypting hosts/common/secrets.yaml..."
sops updatekeys "$COMMON_SECRETS"

# --- 6. Deploy with nixos-anywhere ---
echo "==> Deploying $HOSTNAME via nixos-anywhere..."
nixos-anywhere \
    --flake "$REPO_ROOT#$HOSTNAME" \
    --extra-files "$EXTRA_FILES" \
    --target-host "$SSH_HOST"

echo ""
echo "Done. $HOSTNAME deployed."
echo "  Age key : $AGE_KEY"
echo "  1Pass   : $OP_ITEM_TITLE"
echo ""
echo "Next steps:"
echo "  - Commit hosts/$HOSTNAME/ssh_host_ed25519_key.pub and .sops.yaml"
