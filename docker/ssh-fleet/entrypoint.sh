#!/bin/bash
set -euo pipefail

ssh-keygen -A

if [ -f /run/ssh-fleet/authorized_keys ]; then
    cp /run/ssh-fleet/authorized_keys /home/ansible/.ssh/authorized_keys
    chmod 600 /home/ansible/.ssh/authorized_keys
    chown ansible:ansible /home/ansible/.ssh/authorized_keys
else
    echo "WARNING: no public key found at /run/ssh-fleet/authorized_keys — ansible user will have no way in" >&2
fi

exec /usr/sbin/sshd -D -e
