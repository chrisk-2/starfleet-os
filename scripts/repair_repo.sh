#!/usr/bin/env bash
# scripts/repair_repo.sh
set -euo pipefail

supports_color() { test -t 1 && command -v tput >/dev/null 2>&1 && [ "$(tput colors)" -ge 8 ]; }
if supports_color; then
  BOLD="$(tput bold)"; DIM="$(tput dim)"; RED="$(tput setaf 1)"; GRN="$(tput setaf 2)"
  YLW="$(tput setaf 3)"; BLU="$(tput setaf 4)"; CYA="$(tput setaf 6)"; RST="$(tput sgr0)"
else
  BOLD=""; DIM=""; RED=""; GRN=""; YLW=""; BLU=""; CYA=""; RST=""
fi
info() { echo -e "${BLU}[*]${RST} $*"; }
ok()   { echo -e "${GRN}[OK]${RST} $*"; }
warn() { echo -e "${YLW}[WARN]${RST} $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || true)"
[[ -z "${REPO_ROOT}" ]] && REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"
info "Repo root: ${BOLD}$REPO_ROOT${RST}"

# Scaffold archiso/base
ARCHISO_BASE="archiso/base"
if [[ ! -d "$ARCHISO_BASE" ]]; then
  info "Scaffolding archiso/base"
  mkdir -p "$ARCHISO_BASE"
  [[ -f archiso/packages.base && ! -e $ARCHISO_BASE/packages.base ]] && ln -s ../packages.base "$ARCHISO_BASE/packages.base"
  [[ -f archiso/pacman.conf   && ! -e $ARCHISO_BASE/pacman.conf   ]] && ln -s ../pacman.conf   "$ARCHISO_BASE/pacman.conf"
  cat > "$ARCHISO_BASE/README.md" <<'EOF'
# archiso/base
Symlinked anchors to keep base assets single-sourced.
EOF
  ok "archiso/base scaffolded."
else
  ok "archiso/base already present."
fi

# Ensure airootfs/root exists
AIROOT_ROOT="archiso/airootfs/root"
mkdir -p "$AIROOT_ROOT"
[[ -e "$AIROOT_ROOT/README.keep" ]] || cat > "$AIROOT_ROOT/README.keep" <<'EOF'
This directory exists so ArchISO copies root's home context.
EOF
ok "archiso/airootfs/root is in place."

# Executable bits
info "Ensuring executable bits…"
mapfile -t EXEC_PATHS < <(printf "%s\n" \
  "scripts/*.sh" "roles/*/install.sh" "system/firstboot/*.sh" "*.run" "tools/*.sh")
for pat in "${EXEC_PATHS[@]}"; do
  while IFS= read -r -d '' f; do
    [[ -f "$f" && ! -x "$f" ]] && chmod +x "$f" && info "chmod +x $f"
  done < <(find . -path "./.git" -prune -o -type f -wholename "./$pat" -print0 2>/dev/null || true)
done
ok "Executable bits normalized."

# Tidy oddities
if [[ -e tools/verify.sh.sh ]]; then
  warn "Removing duplicate: tools/verify.sh.sh"
  rm -f tools/verify.sh.sh
  ok "Removed tools/verify.sh.sh"
fi

# Normalize line endings (CRLF -> LF) for all sh/run files
info "Normalizing line endings to LF…"
find . -type f \( -name "*.sh" -o -name "*.run" \) -print0 | xargs -0 sed -i 's/\r$//'
ok "Line endings normalized."

# Verify
if [[ -x scripts/verify_repo.sh ]]; then
  info "Running scripts/verify_repo.sh…"
  if scripts/verify_repo.sh; then
    ok "Repository verification PASSED."
  else
    warn "Repository verification reported issues (see above)."
  fi
else
  warn "scripts/verify_repo.sh not executable; skipping verification."
fi

echo
echo -e "${BOLD}======== REPAIR SUMMARY ========${RST}"
[[ -d "$ARCHISO_BASE" ]] && ok "archiso/base present."
[[ -d "$AIROOT_ROOT"  ]] && ok "archiso/airootfs/root present."
ok "Executables and line endings normalized."
[[ -e tools/verify.sh.sh ]] && warn "tools/verify.sh.sh still present." || ok "No duplicate verify.sh.sh"
