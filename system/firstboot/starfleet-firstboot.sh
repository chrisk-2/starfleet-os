
#!/usr/bin/env bash
set -Eeuo pipefail
LOG=/var/log/starfleet-firstboot.log
exec >>"$LOG" 2>&1

echo ">>> Starfleet first-boot starting: $(date)"
REPO_DIR="/opt/starfleet/repo"
source "$REPO_DIR/scripts/helpers.sh"

# Example: ensure mounts by LABEL (LOGS/VIDEO/BACKUP/MODELS/GRAFANA)
for pair in "LOGS:/srv/logs" "VIDEO:/srv/video" "BACKUP:/srv/backup" "MODELS:/srv/ai" "GRAFANA:/srv/grafana"; do
  IFS=: read -r label mp <<<"$pair"
  write_fstab_label "$label" "$mp" || true
done
mount -a || true

# Pull latest configs (optional)
# clone_or_update_repo "$REPO_DIR" "https://github.com/YOUR_GH_USER/starfleet-os-deployer.git" "main"

# TODO: run per-role finishers if needed
touch /etc/starfleet_firstboot_done
echo ">>> Starfleet first-boot complete."
