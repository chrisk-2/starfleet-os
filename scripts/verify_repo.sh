#!/usr/bin/env bash
set -euo pipefail

root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$root"

red() { printf "\e[31m%s\e[0m\n" "$*"; }
grn() { printf "\e[32m%s\e[0m\n" "$*"; }
ylw() { printf "\e[33m%s\e[0m\n" "$*"; }
die() { red "ERROR: $*"; exit 1; }

need_bins=(git awk sed find xargs sha256sum)
for b in "${need_bins[@]}"; do command -v "$b" >/dev/null || die "missing bin: $b"; done

echo "== Repo top-level =="
tree -L 2 -a . || ls -la

echo
echo "== Required dirs =="
req=(archiso roles scripts system)
missing=0
for d in "${req[@]}"; do
  if [[ ! -d "$d" ]]; then ylw "missing dir: $d"; missing=1; else grn "ok: $d"; fi
done
[[ $missing -eq 0 ]] || die "create missing dirs above"

echo
echo "== Roles sanity =="
roles=(server control drone)
for r in "${roles[@]}"; do
  base="roles/$r"
  [[ -d "$base" ]] || { ylw "missing role dir: $base"; continue; }
  [[ -f "$base/packages.txt" ]] || ylw "$base/packages.txt not found"
  [[ -d "$base/overlay" ]] || ylw "$base/overlay (airootfs overlay) not found"
  grn "role ok-ish: $r"
done

echo
echo "== ArchISO tooling =="
if ! command -v mkarchiso >/dev/null; then
  ylw "mkarchiso not found. On Arch: sudo pacman -S archiso"
else
  grn "mkarchiso present"
fi

echo
echo "== GitHub Actions sanity =="
if [[ -f ".github/workflows/build-iso.yml" ]]; then
  grn ".github/workflows/build-iso.yml found"
else
  ylw "CI workflow missing (will add in this patch)"
fi

echo
grn "Verify: done. If warnings above, fix or proceed to merge/build."
