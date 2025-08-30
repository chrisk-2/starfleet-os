#!/usr/bin/env bash
set -euo pipefail

ROLE="${1:-}"
[[ -n "$ROLE" ]] || { echo "usage: $0 <server|control|drone>"; exit 1; }

root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$root"

BASE="archiso/base"              # put base profile templates here
ROLE_DIR="roles/$ROLE"
OUT="archiso/profiles/starfleet" # canonical composed profile

[[ -d "$ROLE_DIR" ]] || { echo "role not found: $ROLE_DIR"; exit 2; }
mkdir -p "$OUT"

echo "== Compose Starfleet profile from base + role: $ROLE =="

# 1) start clean
rm -rf "$OUT"
mkdir -p "$OUT/airootfs"

# 2) copy base profile skeleton (profiledef.sh, packages.x86_64, etc.)
if [[ -d "$BASE" ]]; then
  cp -a "$BASE/"* "$OUT/"
else
  echo "WARN: base profile missing ($BASE). Creating minimal skeleton."
  cat > "$OUT/profiledef.sh" <<'EOF'
#!/usr/bin/env bash
iso_name="starfleet"
iso_label="STARFLEET_$(date +%Y%m)"
iso_publisher="Starfleet Command"
iso_application="Starfleet OS"
install_dir="arch"
buildmodes=('iso')
bootmodes=('uefi-x64.systemd-boot' 'bios.syslinux.mbr' 'bios.syslinux.eltorito')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
file_permissions=(
  ["/usr/local/bin/starfleet-firstboot.sh"]="0:0:755"
)
EOF
  printf "base-devel\nlinux\nlinux-firmware\nmkinitcpio-archiso\narch-install-scripts\n" > "$OUT/packages.x86_64"
fi

# 3) merge package list
if [[ -f "$ROLE_DIR/packages.txt" ]]; then
  awk 'NF && $1 !~ /^#/' "$ROLE_DIR/packages.txt" >> "$OUT/packages.x86_64"
fi
# de-dup
sort -u -o "$OUT/packages.x86_64" "$OUT/packages.x86_64"

# 4) overlay (airootfs)
if [[ -d "$ROLE_DIR/overlay" ]]; then
  rsync -a "$ROLE_DIR/overlay/" "$OUT/airootfs/"
fi

# 5) system files (firstboot units, etc.)
if [[ -d "system/firstboot" ]]; then
  mkdir -p "$OUT/airootfs/usr/local/bin" "$OUT/airootfs/etc/systemd/system"
  cp -a system/firstboot/starfleet-firstboot.sh "$OUT/airootfs/usr/local/bin/" 2>/dev/null || true
  cp -a system/firstboot/starfleet-firstboot.service "$OUT/airootfs/etc/systemd/system/" 2>/dev/null || true
fi

# 6) pacman.conf fallback
[[ -f "$OUT/pacman.conf" ]] || cat > "$OUT/pacman.conf" <<'EOF'
[options]
HoldPkg     = pacman glibc
Architecture = auto
SigLevel    = Required DatabaseOptional
LocalFileSigLevel = Optional
UseSyslog
Color
ParallelDownloads = 5
[core]
Include = /etc/pacman.d/mirrorlist
[extra]
Include = /etc/pacman.d/mirrorlist
[community]
Include = /etc/pacman.d/mirrorlist
EOF

echo "== Composed profile at: $OUT =="
