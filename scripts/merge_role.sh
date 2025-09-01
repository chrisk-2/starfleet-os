#!/usr/bin/env bash
# Compose a temp archiso profile by merging base + role overlays.
# Usage: scripts/merge_role.sh <ROLE> <TMP_PROFILE_DIR>
set -euo pipefail

ROLE="${1:-}"
OUT_DIR="${2:-}"

if [[ -z "$ROLE" || -z "$OUT_DIR" ]]; then
  echo "Usage: $0 <ROLE: server|control|drone> <TMP_PROFILE_DIR>"
  exit 64
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE_PROFILE="$REPO_DIR/archiso"
ROLE_DIR="$REPO_DIR/roles/$ROLE"

# Sanity checks
[[ -d "$BASE_PROFILE" ]] || { echo "Missing base archiso profile at $BASE_PROFILE"; exit 66; }
[[ -d "$ROLE_DIR" ]] || { echo "Unknown role '$ROLE' (no $ROLE_DIR)"; exit 67; }

# Clean out dir
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

echo "[*] Copying base profile -> $OUT_DIR"
rsync -a --delete "$BASE_PROFILE/" "$OUT_DIR/"

# Merge packages, if present
if [[ -f "$ROLE_DIR/packages.x86_64" ]]; then
  echo "[*] Merging packages.x86_64"
  # De-duplicate while preserving base order: append role packages then sort unique
  awk 'FNR==1{f++} {print $0, f}' "$OUT_DIR/packages.x86_64" <(cat "$ROLE_DIR/packages.x86_64") \
  | awk '{print $1}' | awk 'NF' | sed 's/[[:space:]]\+$//' | awk '!seen[$0]++' > "$OUT_DIR/packages.x86_64.tmp"
  mv "$OUT_DIR/packages.x86_64.tmp" "$OUT_DIR/packages.x86_64"
fi

# Merge pacman.conf fragments (optional)
if [[ -f "$ROLE_DIR/pacman.conf.append" ]]; then
  echo "[*] Appending pacman.conf role fragment"
  cat "$ROLE_DIR/pacman.conf.append" >> "$OUT_DIR/pacman.conf"
fi

# Merge airootfs overlay, if present
if [[ -d "$ROLE_DIR/airootfs" ]]; then
  echo "[*] Overlaying airootfs for role '$ROLE'"
  rsync -a "$ROLE_DIR/airootfs/" "$OUT_DIR/airootfs/"
fi

# Optional: profiledef.sh overrides
if [[ -f "$ROLE_DIR/profiledef.override.sh" ]]; then
  echo "[*] Applying profiledef override"
  cp "$ROLE_DIR/profiledef.override.sh" "$OUT_DIR/profiledef.sh"
fi

# Stamp role for post-install scripts
echo "$ROLE" > "$OUT_DIR/airootfs/etc/starfleet-role"

echo "[✓] Role '$ROLE' merged into: $OUT_DIR"
