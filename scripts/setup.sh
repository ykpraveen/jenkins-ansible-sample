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
