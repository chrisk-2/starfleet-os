#!/usr/bin/env bash
set -Eeuo pipefail

: "${STARFLEET_ROLE:=server}"

echo "[Starfleet] Automated boot script. Role=${STARFLEET_ROLE}"

# Optional: run a role marker if present
if command -v starfleet-role.sh >/dev/null 2>&1; then
  starfleet-role.sh || true
fi

# Your repo already has roles/*/install.sh — call the right one if found
if [[ -x "/root/roles/${STARFLEET_ROLE}/install.sh" ]]; then
  echo "[Starfleet] Executing /root/roles/${STARFLEET_ROLE}/install.sh"
  "/root/roles/${STARFLEET_ROLE}/install.sh"
else
  echo "[Starfleet] NOTE: /root/roles/${STARFLEET_ROLE}/install.sh not found or not executable."
fi
