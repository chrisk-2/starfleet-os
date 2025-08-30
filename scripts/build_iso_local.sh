#!/usr/bin/env bash
set -euo pipefail

ROLE="${1:-server}"
WORKDIR="${WORKDIR:-/tmp/starfleet-build-$ROLE}"
PROFILE="archiso/profiles/starfleet"

root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$root"

[[ -d "$PROFILE" ]] || { echo "profile not found: $PROFILE (run merge_role.sh)"; exit 2; }

echo "== Building ISO for role: $ROLE =="
sudo rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"

# ArchISO requires root for mounting/squashfs
sudo mkarchiso -v -w "$WORKDIR" -o "out/iso" "$PROFILE"

echo
echo "== Done. ISOs in out/iso =="
ls -lh out/iso
