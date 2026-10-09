#!/usr/bin/env bash
set -euo pipefail
# Configure the existing root subvolume; personal files in /home are separate.
if (( EUID == 0 )); then
    printf 'Run as your desktop user; the privileged steps use sudo.\n' >&2
    exit 1
fi
command -v snapper >/dev/null
config_file=/etc/snapper/configs/root
if [[ ! -f "$config_file" ]] || ! rg -q '^SUBVOLUME="/"$' "$config_file" || ! rg -q '^FSTYPE="btrfs"$' "$config_file"; then
    printf 'Expected an existing Btrfs Snapper root configuration; nothing changed.\n' >&2
    exit 1
fi
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
policy="$script_dir/../system/snapper/root-timeline.conf"
settings=()
while IFS= read -r setting || [[ -n "$setting" ]]; do
    [[ -z "$setting" || "$setting" == \#* ]] && continue
    if [[ ! "$setting" =~ ^TIMELINE_[A-Z_]+=\"[a-z0-9]+\"$ ]]; then
        printf 'Invalid timeline setting: %s\n' "$setting" >&2
        exit 1
    fi
    settings+=("${setting//\"/}")
done < "$policy"
if (( ${#settings[@]} == 0 )); then
    printf 'No timeline settings found; nothing changed.\n' >&2
    exit 1
fi
sudo -v
saved="/var/lib/snapper/config-backups/root-$(date +%Y%m%d-%H%M%S).conf"
sudo install -Dm600 "$config_file" "$saved"
printf 'Original configuration saved: %s\n' "$saved"
sudo snapper -c root set-config "${settings[@]}"
# Verify snapshot creation before enabling the timer.
snapshot=$(sudo snapper -c root create --read-only --cleanup-algorithm timeline --description 'Scheduled system recovery baseline' --print-number)
sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer
sudo snapper -c root get-config
systemctl is-active snapper-timeline.timer snapper-cleanup.timer
systemctl list-timers --all snapper-timeline.timer snapper-cleanup.timer --no-pager
printf '\nCreated system recovery snapshot %s. Hourly snapshots and cleanup are enabled.\n' "$snapshot"
printf 'Inspect snapshots: sudo snapper -c root list\n'
printf 'Root snapshots do not include the separate /home subvolume.\n'
