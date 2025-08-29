#!/usr/bin/env bash
set -Eeuo pipefail
ROLE="${1:?usage: merge_role.sh <server|control|drone>}"

echo ">>> Preparing profile for role: $ROLE"

# 1) Compose packages.x86_64
: > archiso/packages.x86_64
cat archiso/packages.base >> archiso/packages.x86_64
if [[ -f "roles/${ROLE}/packages.role" ]]; then
  echo "" >> archiso/packages.x86_64
  cat "roles/${ROLE}/packages.role" >> archiso/packages.x86_64
fi

# 2) Overlay role airootfs (optional)
if [[ -d "roles/${ROLE}/airootfs" ]]; then
  rsync -a "roles/${ROLE}/airootfs/" "archiso/airootfs/"
fi

# 3) Ensure firstboot helper is present inside live ISO
install -Dm755 system/firstboot/starfleet-firstboot.sh archiso/airootfs/usr/local/bin/starfleet-firstboot || true

echo ">>> Done composing profile for role: $ROLE"
