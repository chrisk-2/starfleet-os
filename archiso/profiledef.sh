#!/usr/bin/env bash
# shellcheck disable=SC2034

: "${STARFLEET_ROLE:=server}"

# Prefer semantic tag version (vX.Y.Z) if present; else date
if [[ -n "${GITHUB_REF_NAME:-}" && "${GITHUB_REF_NAME}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  _ver="${GITHUB_REF_NAME#v}"
else
  _ver="$(date +%Y.%m.%d)"
fi

iso_name="starfleet-${STARFLEET_ROLE}"
iso_label="STFL-${STARFLEET_ROLE^^}-${_ver}"
iso_publisher="Starfleet OS"
iso_application="Starfleet ${STARFLEET_ROLE} live ISO"
iso_version="${_ver}"

install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux.mbr' 'bios.syslinux.eltorito' 'uefi-x64.grub' 'uefi-ia32.grub' 'uefi-ia32.systemd-boot' 'uefi-x64.systemd-boot')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '19')
file_permissions=(
  [/root]=0:0:750
  [/root/.automated_script.sh]=0:0:755
  [/usr/local/bin/starfleet-firstboot]=0:0:755
)
