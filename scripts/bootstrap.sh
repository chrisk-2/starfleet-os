
#!/usr/bin/env bash
set -Eeuo pipefail
ROLE="${1:-drone}"

REPO_URL="${REPO_URL:-https://github.com/YOUR_GH_USER/starfleet-os-deployer.git}"
BRANCH="${BRANCH:-main}"
TARGET="/mnt/starfleet"

echo ">>> Starfleet bootstrap starting for role: $ROLE"
command -v git >/dev/null || pacman -Sy --noconfirm git
[[ -d "$TARGET" ]] || mkdir -p "$TARGET"
mountpoint -q /mnt || { echo ">>> Mounting root to /mnt using archinstall-style assumptions..."; }

# If we're on a stock Arch ISO, we're in RAM; just clone to /root and run network installer.
cd /root
if [[ ! -d starfleet-os-deployer ]]; then
  git clone --depth 1 -b "$BRANCH" "$REPO_URL"
fi
cd starfleet-os-deployer

# Run the role installer from live environment; it will handle disk, pacstrap, fstab, etc.
exec roles/"$ROLE"/install.sh
