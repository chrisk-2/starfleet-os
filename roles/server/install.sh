
#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/../../scripts/helpers.sh"

# Minimal sanity
need bash curl git pacman-contrib

# 1) Partition + format (simple single-disk demo; customize for your lab)
DISK="${DISK:-/dev/sda}"
log "Wiping and partitioning $DISK (GPT + single ext4)..."
sgdisk --zap-all "$DISK"
parted -s "$DISK" mklabel gpt mkpart root 1MiB 100%
sleep 1
PART="${DISK}1"
mkfs.ext4 -F "$PART" -L ROOT

# 2) Mount and base install
mount "$PART" /mnt
pacstrap -K /mnt base linux linux-firmware networkmanager git vim sudo

# 3) fstab and chroot
genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt /bin/bash -s <<'CHROOT'
set -Eeuo pipefail
systemctl enable NetworkManager
useradd -m -G wheel ogre || true
echo "ogre:ogre" | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
CHROOT

# 4) Copy repo into new system for first boot
mkdir -p /mnt/opt/starfleet
cp -a "$(cd "$(dirname "$0")/../.." && pwd)" /mnt/opt/starfleet/repo

# 5) Enable first-boot finisher
cp -a /mnt/opt/starfleet/repo/system/firstboot/* /mnt/etc/systemd/system/
arch-chroot /mnt systemctl enable starfleet-firstboot.service

log "Base install complete. You can now reboot."

# Server role specifics (packages, services)
arch-chroot /mnt /bin/bash -s <<'CHROOT'
set -Eeuo pipefail
pacman -Sy --noconfirm docker docker-compose tmux
systemctl enable docker
# Place additional server configs here (WireGuard, Grafana, Loki, etc.)
CHROOT
