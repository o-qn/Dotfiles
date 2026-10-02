#!/usr/bin/env bash
set -euo pipefail
config_root="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
case "${1:-help}" in
  files)
    exec env QT_QPA_PLATFORMTHEME=qt6ct pcmanfm-qt "${2:-$HOME}"
    ;;
  help)
    exec python3 "$config_root/scripts/shortcuts.py"
    ;;
  reload)
    if report=$(Hyprland --verify-config -c "$config_root/hyprland.lua" 2>&1); then
      if report=$(noctalia config validate 2>&1) && ! [[ "$report" == *"WARN "* ]]; then
        hyprctl reload
        noctalia msg config-reload
        noctalia msg notification-show "Desktop" "Desktop configuration reloaded."
      else
        noctalia msg notification-show "Noctalia configuration needs attention" "$report"
        exit 1
      fi
    else
      noctalia msg notification-show "Hyprland configuration needs attention" "$report"
      exit 1
    fi
    ;;
  doctor)
    printf '\033[38;2;122;162;247mDESKTOP CHECK\033[0m\n\n'
    for app in Hyprland hyprctl noctalia kitty zen-browser pcmanfm-qt qt6ct; do
      if command -v "$app" >/dev/null; then printf '  OK       %s\n' "$app"; else printf '  MISSING  %s\n' "$app"; fi
    done
    printf '\nHyprland configuration:\n'
    hyprctl configerrors || true
    printf '\nNoctalia configuration:\n'
    noctalia config validate || true
    printf '\nShell status:\n'
    noctalia msg status || true
    printf '\nMonitors:\n'
    hyprctl monitors || true
    printf '\nPress Enter to close.'
    read -r _
    ;;
  *) printf 'Usage: desktop.sh {files|help|reload|doctor}\n' >&2; exit 2 ;;
esac
