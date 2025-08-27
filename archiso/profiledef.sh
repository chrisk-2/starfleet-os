
profile="starfleet"
profile_desc="Starfleet OS Deployer ISO"
install_dir="arch"
bootmodes=('uefi-x64.systemd-boot.esp' 'bios.syslinux.mbr')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=("-comp" "xz" "-b" "1M" "-Xbcj" "x86")
file_permissions=(
  ["/root/.automated_script.sh"]="0:0:0755"
)
