#!/usr/bin/env bash
# scripts/verify_repo.sh
set -euo pipefail

# ----- tiny ui -----
supports_color() { test -t 1 && command -v tput >/dev/null 2>&1 && [ "$(tput colors)" -ge 8 ]; }
if supports_color; then
  BOLD="$(tput bold)"; DIM="$(tput dim)"; RED="$(tput setaf 1)"; GRN="$(tput setaf 2)"
  YLW="$(tput setaf 3)"; BLU="$(tput setaf 4)"; RST="$(tput sgr0)"
else
  BOLD=""; DIM=""; RED=""; GRN=""; YLW=""; BLU=""; RST=""
fi
ok()   { echo -e "  ${GRN}•${RST} $*"; }
warn() { echo -e "  ${YLW}•${RST} $*"; }
bad()  { echo -e "  ${RED}•${RST} $*"; }
hdr()  { echo -e "${BOLD}$*${RST}"; }

# ----- repo root -----
if git rev-parse --show-toplevel >/dev/null 2>&1; then
  REPO_ROOT="$(git rev-parse --show-toplevel)"
else
  REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi
cd "$REPO_ROOT"

FAIL=0
miss() { bad "missing: $1"; FAIL=1; }
chk_dir()  { [[ -d "$1" ]] && ok "dir: $1" || miss "dir: $1"; }
chk_file() { [[ -f "$1" ]] && ok "file: $1" || miss "file: $1"; }

hdr "== Top-level structure =="
chk_dir archiso
chk_dir roles
chk_dir scripts
chk_dir system

hdr ""
hdr "== ArchISO base/profile =="
chk_file archiso/profiledef.sh
chk_file archiso/packages.base
chk_file archiso/pacman.conf
# Optional scaffold we created:
[[ -d archiso/base ]] && ok "dir: archiso/base" || warn "optional: archiso/base not present (ok if profile points elsewhere)"
# airootfs/root exists to carry root's home artifacts:
[[ -d archiso/airootfs/root ]] && ok "dir: archiso/airootfs/root" || warn "optional: archiso/airootfs/root not present"

hdr ""
hdr "== Roles =="
for role in control drone server; do
  if [[ -d "roles/$role" ]]; then
    ok "role dir: roles/$role"
    [[ -f "roles/$role/install.sh" ]]     && ok "  $role: install.sh"      || miss "roles/$role/install.sh"
    [[ -f "roles/$role/packages.role" ]]  && ok "  $role: packages.role"   || miss "roles/$role/packages.role"
    [[ -f "roles/$role/packages.x86_64" ]]&& ok "  $role: packages.x86_64" || miss "roles/$role/packages.x86_64"
    # server sometimes has deeper airootfs overlay:
    [[ -d "roles/$role/airootfs" ]] && ok "  $role: airootfs overlay (optional)"
  else
    miss "roles/$role"
  fi
done

hdr ""
hdr "== Firstboot (system/firstboot) =="
chk_dir system/firstboot
chk_file system/firstboot/starfleet-firstboot.service
chk_file system/firstboot/starfleet-firstboot.sh
# sanity-check minimal sections exist in service file
if [[ -f system/firstboot/starfleet-firstboot.service ]]; then
  if grep -q "^\s*\[Unit\]" system/firstboot/starfleet-firstboot.service \
     && grep -q "^\s*\[Service\]" system/firstboot/starfleet-firstboot.service; then
    ok "unit sections present"
  else
    warn "unit sections look incomplete"
  fi
fi

hdr ""
hdr "== Build scripts =="
chk_file scripts/merge_role.sh
chk_file scripts/build_iso_local.sh
chk_file scripts/verify_repo.sh
[[ -f scripts/helpers.sh ]] && ok "helpers.sh" || warn "helpers.sh is optional"

hdr ""
hdr "== CI workflows =="
if [[ -d .github/workflows ]]; then
  ok "workflows dir present"
  [[ -f .github/workflows/build-iso.yml ]] && ok "build-iso.yml" || warn "build-iso.yml missing (optional if using another workflow)"
  [[ -f .github/workflows/build-archiso.yml ]] && ok "build-archiso.yml" || warn "build-archiso.yml missing (optional)"
else
  warn ".github/workflows missing (no CI configured)"
fi

hdr ""
hdr "== Tooling hints / deliverables =="
for f in STARFLEET_INSTALL_CONTROL.run STARFLEET_INSTALL_DRONE.run STARFLEET_INSTALL_SERVER.run; do
  [[ -f "$f" ]] && ok "deliverable: $f" || warn "deliverable missing: $f"
done
for f in Starfleet_OS_Install_and_Boot_Checklist.pdf Starfleet_OS_Install_Checklist.docx Starfleet_OS_Install_Checklist_LCARS.pdf Starfleet_OS_Quick_Ref.pdf; do
  [[ -f "$f" ]] && ok "doc: $f" || warn "doc missing: $f"
done

hdr ""
hdr "======== VERIFY SUMMARY ========"
if [[ $FAIL -eq 0 ]]; then
  ok "All required components present."
  exit 0
else
  bad "Repository has missing required components."
  exit 1
fi
