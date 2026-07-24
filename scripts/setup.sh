#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

mkdir -p secrets/ssh

if [ ! -f secrets/ssh/id_ed25519 ]; then
    ssh-keygen -t ed25519 -N "" -f secrets/ssh/id_ed25519 -C "ansible-control"
    echo "Generated new SSH keypair at secrets/ssh/"
else
    echo "SSH keypair already exists at secrets/ssh/ — leaving as-is"
fi

chmod 600 secrets/ssh/id_ed25519 2>/dev/null || true
actual_mode=$(stat -c '%a' secrets/ssh/id_ed25519 2>/dev/null || stat -f '%Lp' secrets/ssh/id_ed25519 2>/dev/null || echo unknown)
if [ "$actual_mode" != "600" ]; then
    cat >&2 <<EOF

WARNING: secrets/ssh/id_ed25519 has permissions $actual_mode after chmod 600 was attempted.
ssh will refuse to use a private key that isn't 600 and will silently fall back to
password auth — you'll hit this later as a confusing "Permission denied" or unexpected
password prompt on the fleet hosts, not as an error here.

This almost always means the repo is on a filesystem that doesn't enforce Unix
permissions, e.g. a Windows drive mounted into WSL2 at /mnt/c/..., or a VirtualBox/
Parallels shared folder. Fix: move the repo (or at least secrets/ssh/) onto a native
Linux filesystem path — e.g. under ~/ inside WSL2, not /mnt/c/... — then re-run this
script.
EOF
fi
