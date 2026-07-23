#!/bin/sh
set -eu

: "${ANSIBLE_VAULT_PASSWORD:?ANSIBLE_VAULT_PASSWORD must be set — export it locally, or inject it as a Jenkins credential at runtime. It is never written to disk in this repo.}"
echo "$ANSIBLE_VAULT_PASSWORD"
