#!/usr/bin/env bash
# Build a Starfleet OS ISO for a given role using mkarchiso.
# Usage:
#   scripts/build_iso_local.sh server
#   scripts/build_iso_local.sh control
#   scripts/build_iso_local.sh drone
#
# Env toggles:
#   OUT_DIR=out WORK_DIR=work BUILD_PROFILE=.build_profile CACHE_DIR=.cache
#   ARCHISO_OPTS="--v" etc.
set -euo pipefail

ROLE="${1:-}"
if [[ -z "$ROLE" ]]; then
  echo "Usage: $0 <ROLE: server|control|drone>"
  exit 64
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_PROFILE="${BUILD_PROFILE:-$REPO_DIR/.build_profile/$ROLE}"
WORK_DIR="${WORK_DIR:-$REPO_DIR/work/$ROLE}"
OUT_DIR="${OUT_DIR:-$REPO_DIR/out}"
CACHE_DIR="${CACHE_DIR:-$REPO_DIR/.cache}"
ARCHISO_OPTS="${ARCHISO_OPTS:--v}"

# deps
if ! command -v mkarchiso >/dev/null 2>&1; then
  echo "[*] Installing archiso..."
  sudo pacman -Sy --needed --noconfirm archiso
fi

# compose temp profile
mkdir -p "$(dirname "$BUILD_PROFILE")"
"$REPO_DIR/scripts/merge_role.sh" "$ROLE" "$BUILD_PROFILE"

# Ensure required dirs
mkdir -p "$WORK_DIR" "$OUT_DIR" "$CACHE_DIR"

# Optional: version stamp
VERSION="$(date +%Y.%m.%d)-$ROLE"
echo "$VERSION" > "$BUILD_PROFILE/version"

# Build
echo "[*] Building ISO for role '$ROLE'"
sudo mkarchiso $ARCHISO_OPTS \
  -w "$WORK_DIR" \
  -o "$OUT_DIR" \
  -C "$BUILD_PROFILE/pacman.conf" \
  -D "$CACHE_DIR" \
  "$BUILD_PROFILE"

# Find artifact and rename to friendly name
ISO_SRC="$(ls -1t "$OUT_DIR"/*.iso | head -n1 || true)"
if [[ -n "${ISO_SRC}" ]]; then
  DEST="$OUT_DIR/starfleet-os-${ROLE}-${VERSION}.iso"
  mv -f "$ISO_SRC" "$DEST"
  echo "[✓] ISO: $DEST"
else
  echo "[!] Build did not produce an ISO in $OUT_DIR"
  exit 65
fi
