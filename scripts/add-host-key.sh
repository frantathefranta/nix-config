#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: $(basename "$0") <ssh-host> <hostname>"
    echo ""
    echo "  ssh-host   SSH connection target (e.g. root@1.2.3.4)"
    echo "  hostname   NixOS hostname — used for hosts/<hostname>/ dir and SOPS anchor"
    echo ""
    echo "Requires: ssh-to-age, sops (available in devshell)"
    exit 1
}

[[ $# -ne 2 ]] && usage

SSH_HOST="$1"
HOSTNAME="$2"

if ! command -v ssh-to-age &>/dev/null; then
    echo "error: ssh-to-age not found — run this script from within the devshell" >&2
    exit 1
fi
if ! command -v sops &>/dev/null; then
    echo "error: sops not found — run this script from within the devshell" >&2
    exit 1
fi

REPO_ROOT="$(git -C "$(dirname "$(realpath "$0")")" rev-parse --show-toplevel)"
HOST_PATH="$REPO_ROOT/hosts/$HOSTNAME"
PUB_KEY_FILE="$HOST_PATH/ssh_host_ed25519_key.pub"
SOPS_YAML="$REPO_ROOT/.sops.yaml"
COMMON_SECRETS="$REPO_ROOT/hosts/common/secrets.yaml"

mkdir -p "$HOST_PATH"

echo "==> Copying SSH host key from $SSH_HOST..."
ssh "$SSH_HOST" 'cat /etc/ssh/ssh_host_ed25519_key.pub' > "$PUB_KEY_FILE"
echo "    Saved to $PUB_KEY_FILE"

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
    lines = f.readlines()

content = ''.join(lines)

# --- keys section: add or update &hostname anchor ---
anchor_pattern = re.compile(rf'^( *- &{re.escape(hostname)} )age1\S+', re.MULTILINE)
anchor_line    = f'    - &{hostname} {age_key}'

if anchor_pattern.search(content):
    content = anchor_pattern.sub(lambda m: m.group(1) + age_key, content)
    print(f'    Updated existing key for {hostname}')
else:
    # Insert before the yubikey comment (keeps NC312237 at the bottom of hosts)
    insert_before = re.search(r'^    # age-plugin-yubikey', content, re.MULTILINE)
    if insert_before:
        pos = insert_before.start()
    else:
        # Fallback: insert before &NC312237 line
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
in_common   = False
in_age      = False
last_age_idx = -1
inserted    = False

for i, line in enumerate(lines):
    if 'path_regex: hosts/common/secrets' in line:
        in_common = True
    elif in_common and re.match(r'\s+- age:\s*$', line):
        in_age = True
    elif in_common and in_age and re.match(r'\s+- \*\S', line):
        if f'*{hostname}' in line:
            print(f'    *{hostname} already present in common secrets rule')
            inserted = True  # already there, skip insertion
            break
        last_age_idx = i
    elif in_common and in_age and re.match(r'\s+pgp:', line):
        # Insert after the last age ref
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

content = ''.join(lines)

with open(sops_yaml, 'w') as f:
    f.write(content)
PYEOF

echo "==> Re-encrypting hosts/common/secrets.yaml..."
sops updatekeys "$COMMON_SECRETS"

echo ""
echo "Done. Host '$HOSTNAME' added with age key:"
echo "  $AGE_KEY"
echo ""
echo "Next steps:"
echo "  - Commit hosts/$HOSTNAME/ssh_host_ed25519_key.pub and .sops.yaml"
echo "  - Add a nixosConfigurations entry in flake.nix"
