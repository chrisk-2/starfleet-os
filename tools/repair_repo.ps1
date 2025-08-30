<# Starfleet OS Repo Repair (PowerShell)
   Safely scaffolds missing pieces. Never overwrites existing files.
   Usage:
     .\tools\repair_repo.ps1
     .\tools\repair_repo.ps1 -AutoApprove
#>
[CmdletBinding()]
param([switch]$AutoApprove)

$ErrorActionPreference='Stop'
function Info($t){ Write-Host $t -ForegroundColor Cyan }
function Ok($t){ Write-Host $t -ForegroundColor Green }
function Do($path,$content){
  if(Test-Path $path){ Write-Host "skip (exists): $path" -ForegroundColor Yellow; return }
  New-Item -ItemType Directory -Force -Path (Split-Path $path) | Out-Null
  Set-Content -LiteralPath $path -Value $content -Encoding UTF8
  Ok "created: $path"
}

# Confirm
if(-not $AutoApprove){
  Write-Host "This will create missing skeleton files (no overwrite). Continue? [Y/N]" -NoNewline
  $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
  Write-Host ""; if($key.Character -notin @('y','Y')){ Write-Host "Aborted."; exit 1 }
}

# Ensure dirs
$dirs = @("archiso/base","archiso/profiles",".github/workflows","roles/server/overlay","roles/control/overlay","roles/drone/overlay","scripts","system/firstboot","tools")
foreach($d in $dirs){ New-Item -ItemType Directory -Force -Path $d | Out-Null }

# Base profile
$profiledef = @"
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
"@
$basepkgs = @"
base
linux
linux-firmware
mkinitcpio-archiso
arch-install-scripts
"@
$pacmanConf = @"
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
"@
Do "archiso/base/profiledef.sh" $profiledef
Do "archiso/base/packages.x86_64" $basepkgs
Do "archiso/base/pacman.conf" $pacmanConf

# First-boot unit + script
$unit = @"
[Unit]
Description=Starfleet First Boot
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/starfleet-firstboot.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
"@
$firstboot = @"
#!/usr/bin/env bash
set -euo pipefail
echo "[Starfleet] First boot tasks starting..."
# Example: create marker and disable service so it runs once
touch /var/log/starfleet-firstboot.ran
systemctl disable starfleet-firstboot.service || true
echo "[Starfleet] First boot tasks done."
"@
Do "system/firstboot/starfleet-firstboot.service" $unit
Do "system/firstboot/starfleet-firstboot.sh" $firstboot

# Role package placeholders (won't overwrite)
$rolePkgs = @"
# one package per line, '#' for comments
# add role-specific packages here (example):
nano
vim
htop
"@
Do "roles/server/packages.txt" $rolePkgs
Do "roles/control/packages.txt" $rolePkgs
Do "roles/drone/packages.txt" $rolePkgs

# Linux build/merge scripts
$merge = @"
#!/usr/bin/env bash
set -euo pipefail
ROLE="\${1:-}"
[[ -n "\$ROLE" ]] || { echo "usage: \$0 <server|control|drone>"; exit 1; }
root="\$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "\$root"
BASE="archiso/base"
ROLE_DIR="roles/\$ROLE"
OUT="archiso/profiles/starfleet"
[[ -d "\$ROLE_DIR" ]] || { echo "role not found: \$ROLE_DIR"; exit 2; }
rm -rf "\$OUT"; mkdir -p "\$OUT/airootfs"
if [[ -d "\$BASE" ]]; then cp -a "\$BASE/"* "\$OUT/"; fi
[[ -f "\$OUT/packages.x86_64" ]] || : > "\$OUT/packages.x86_64"
if [[ -f "\$ROLE_DIR/packages.txt" ]]; then
  awk 'NF && \$1 !~ /^#/' "\$ROLE_DIR/packages.txt" >> "\$OUT/packages.x86_64"
  sort -u -o "\$OUT/packages.x86_64" "\$OUT/packages.x86_64"
fi
if [[ -d "\$ROLE_DIR/overlay" ]]; then rsync -a "\$ROLE_DIR/overlay/" "\$OUT/airootfs/"; fi
if [[ -d "system/firstboot" ]]; then
  mkdir -p "\$OUT/airootfs/usr/local/bin" "\$OUT/airootfs/etc/systemd/system"
  cp -a system/firstboot/starfleet-firstboot.sh "\$OUT/airootfs/usr/local/bin/" 2>/dev/null || true
  cp -a system/firstboot/starfleet-firstboot.service "\$OUT/airootfs/etc/systemd/system/" 2>/dev/null || true
fi
[[ -f "\$OUT/pacman.conf" ]] || cp -a archiso/base/pacman.conf "\$OUT/pacman.conf"
echo "Composed profile at: \$OUT"
"@
$build = @"
#!/usr/bin/env bash
set -euo pipefail
ROLE="\${1:-server}"
WORKDIR="\${WORKDIR:-/tmp/starfleet-build-\$ROLE}"
PROFILE="archiso/profiles/starfleet"
root="\$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "\$root"
[[ -d "\$PROFILE" ]] || { echo "profile not found: \$PROFILE (run merge_role.sh)"; exit 2; }
sudo rm -rf "\$WORKDIR"; mkdir -p "\$WORKDIR"
sudo mkarchiso -v -w "\$WORKDIR" -o "out/iso" "\$PROFILE"
echo "ISOs in out/iso"; ls -lh out/iso
"@
$verify = @"
#!/usr/bin/env bash
set -euo pipefail
echo 'Use tools/verify_repo.ps1 on Windows or run detailed checks in CI.'
"@
Do "scripts/merge_role.sh" $merge
Do "scripts/build_iso_local.sh" $build
Do "scripts/verify_repo.sh" $verify

# GitHub Actions workflow
$ci = @"
name: Build Starfleet OS ISOs
on:
  push:
    branches: [ "main" ]
    paths-ignore:
      - "README.md"
  workflow_dispatch:
  push:
    tags:
      - "v*.*.*"
permissions: { contents: write }
jobs:
  build:
    runs-on: ubuntu-22.04
    strategy: { fail-fast: false, matrix: { role: [server, control, drone] } }
    steps:
      - uses: actions/checkout@v4
      - name: Build ISO in Arch container
        uses: addnab/docker-run-action@v3
        with:
          image: archlinux:latest
          options: -v \${{ github.workspace }}:/repo
          run: |
            set -euo pipefail
            pacman -Syu --noconfirm archiso rsync git
            cd /repo
            chmod +x scripts/*.sh || true
            ./scripts/merge_role.sh \${{ matrix.role }}
            WORKDIR=/tmp/build-\${{ matrix.role }} ./scripts/build_iso_local.sh \${{ matrix.role }}
            mkdir -p /repo/out/ci/\${{ matrix.role }}
            cp -v out/iso/*.iso /repo/out/ci/\${{ matrix.role }}/
      - name: Upload artifact (\${{ matrix.role }})
        uses: actions/upload-artifact@v4
        with:
          name: starfleet-\${{ matrix.role }}-isos
          path: out/ci/\${{ matrix.role }}/*.iso
  release:
    if: startsWith(github.ref, 'refs/tags/v')
    needs: [build]
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/download-artifact@v4
        with: { path: ./artifacts }
      - uses: softprops/action-gh-release@v2
        with:
          files: artifacts/**/*/*.iso
          generate_release_notes: true
"@
Do ".github/workflows/build-iso.yml" $ci

Ok "Repair complete. Next: run tools\\verify_repo.ps1 again."
