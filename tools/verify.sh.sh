#!/usr/bin/env bash
set -euo pipefail

LABEL="STARFLEET"
MOUNTPOINT="${MOUNTPOINT:-/media/$USER/$LABEL}"
REPO_DIR="$MOUNTPOINT/starfleet-os"

red()   { printf "\033[31m%s\033[0m\n" "$*"; }
green() { printf "\033[32m%s\033[0m\n" "$*"; }
yellow(){ printf "\033[33m%s\033[0m\n" "$*"; }

echo "=== Starfleet USB Verification (Linux) ==="

# 1) Find mountpoint if not provided
if [[ ! -d "$MOUNTPOINT" ]]; then
  # Try lsblk by label
  if mp=$(lsblk -o LABEL,MOUNTPOINT -nr | awk -v lbl="$LABEL" '$1==lbl{print $2; exit}'); then
    if [[ -n "${mp:-}" ]]; then
      MOUNTPOINT="$mp"
    fi
  fi
fi

if [[ ! -d "$MOUNTPOINT" ]]; then
  red "✗ Could not locate mountpoint for label '$LABEL'."
  echo "  Hint: mount the USB or set MOUNTPOINT=/run/media/$USER/$LABEL (Fedora) and rerun."
  exit 1
fi

echo "Mountpoint: $MOUNTPOINT"

# 2) Filesystem info
if command -v findmnt >/dev/null 2>&1; then
  FS=$(findmnt -no FSTYPE "$MOUNTPOINT" || true)
else
  FS=$(df -T "$MOUNTPOINT" 2>/dev/null | awk 'NR==2{print $2}')
fi
SIZE=$(df -h "$MOUNTPOINT" | awk 'NR==2{print $2}')
FREE=$(df -h "$MOUNTPOINT" | awk 'NR==2{print $4}')

if [[ -z "${FS:-}" ]]; then
  yellow "(!) Could not determine filesystem type."
else
  echo "Filesystem: $FS   Size: $SIZE   Free: $FREE"
  if [[ "$FS" != "exfat" && "$FS" != "fuseblk.exfat" && "$FS" != "exfat-fuse" ]]; then
    yellow "(!) Expected exFAT. Proceeding anyway."
  fi
fi

# 3) Repo presence
if [[ -d "$REPO_DIR/.git" ]]; then
  green "✔ Repo present: $REPO_DIR"
else
  red "✗ Repo not found at $REPO_DIR"
  echo "  Hint: git clone https://github.com/chrisk-2/starfleet-os.git \"$REPO_DIR\""
  exit 2
fi

# 4) Git sanity
cd "$REPO_DIR"
echo
echo "--- git status ---"
git status

echo
echo "--- git config (repo) ---"
echo "core.autocrlf = $(git config --get core.autocrlf || echo '<unset>')"
echo "core.eol      = $(git config --get core.eol || echo '<unset>')"
echo "core.longpaths= $(git config --get core.longpaths || echo '<unset>')"

echo
green "All checks complete."
