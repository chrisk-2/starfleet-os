
#!/usr/bin/env bash
set -Eeuo pipefail

log() { printf "[%s] %s\n" "$(date +%F\ %T)" "$*" >&2; }

need() {
  for b in "$@"; do
    command -v "$b" >/dev/null || { log "Installing $b..."; pacman -Sy --noconfirm "$b"; }
  done
}

write_fstab_label() {
  local label="$1" mp="$2"
  [[ -d "$mp" ]] || mkdir -p "$mp"
  grep -q "LABEL=${label} " /etc/fstab || echo "LABEL=${label} ${mp} ext4 noatime 0 2" >> /etc/fstab
}

enable_firstboot() {
  systemctl enable starfleet-firstboot.service
}

clone_or_update_repo() {
  local dest="$1" url="$2" branch="$3"
  if [[ -d "$dest/.git" ]]; then
    git -C "$dest" fetch --depth 1 origin "$branch"
    git -C "$dest" reset --hard "origin/$branch"
  else
    rm -rf "$dest"
    git clone --depth 1 -b "$branch" "$url" "$dest"
  fi
}
