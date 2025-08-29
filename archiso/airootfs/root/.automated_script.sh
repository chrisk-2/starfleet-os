#!/usr/bin/env bash
set -Eeuo pipefail
: "${STARFLEET_ROLE:=server}"

echo "[Starfleet] Automated live boot — role=${STARFLEET_ROLE}"

if [[ -x "/root/roles/${STARFLEET_ROLE}/install.sh" ]]; then
  "/root/roles/${STARFLEET_ROLE}/install.sh"
else
  echo "[Starfleet] /root/roles/${STARFLEET_ROLE}/install.sh not found; interactive shell."
fi
