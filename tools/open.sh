@'#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
git status
if command -v code >/dev/null 2>&1; then
  code .
else
  echo "VS Code not found; staying in shell."
  exec "${SHELL:-/bin/bash}"
fi
'@ | Set-Content -Path D:\starfleet-os\tools\open.sh -Encoding UTF8
