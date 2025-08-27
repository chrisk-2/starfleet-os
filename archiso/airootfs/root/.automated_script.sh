
#!/usr/bin/env bash
# Runs automatically on ISO boot to clone this repo and prompt for role (default: drone)
set -Eeuo pipefail
ROLE="${1:-drone}"
REPO_URL="${REPO_URL:-https://github.com/YOUR_GH_USER/starfleet-os-deployer.git}"
BRANCH="${BRANCH:-main}"

echo "=== Starfleet ISO autostart ==="
pacman -Sy --noconfirm git curl
cd /root
if [[ ! -d starfleet-os-deployer ]]; then
  git clone --depth 1 -b "$BRANCH" "$REPO_URL"
fi
cd starfleet-os-deployer

read -r -p "Choose role [server/control/drone] (default: drone): " CHOICE || true
ROLE="${CHOICE:-$ROLE}"
exec roles/"$ROLE"/install.sh
