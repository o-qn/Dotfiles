#!/usr/bin/env bash
set -euo pipefail
# Run as your desktop user. Only the package/module/udev steps require sudo.
install_packages() {
  if command -v pacman >/dev/null; then
    sudo pacman -S --needed "$@"
  elif command -v dnf >/dev/null; then
    sudo dnf install -y "$@"
  elif command -v apt-get >/dev/null; then
    sudo apt-get install -y "$@"
  elif command -v zypper >/dev/null; then
    sudo zypper install -y "$@"
  elif command -v xbps-install >/dev/null; then
    sudo xbps-install -S "$@"
  elif command -v apk >/dev/null; then
    sudo apk add "$@"
  elif command -v emerge >/dev/null; then
    sudo emerge --noreplace "$@"
  else
    printf 'Install required package(s) manually with your distro package manager: %s\n' "$*" >&2
    exit 1
  fi
}

if ! command -v ddcutil >/dev/null; then
  install_packages ddcutil
fi

# Ensure i2c-dev loads at boot and grants active-session uaccess on distros whose package omits them.
if ! grep -Eqs '^i2c-dev$' /etc/modules-load.d/*.conf /usr/lib/modules-load.d/*.conf /lib/modules-load.d/*.conf; then
  printf 'i2c-dev\n' | sudo tee /etc/modules-load.d/ddcutil.conf >/dev/null
fi
if ! grep -Eqs 'i2c-dev.*uaccess|uaccess.*i2c-dev' /etc/udev/rules.d/*.rules /usr/lib/udev/rules.d/*.rules /lib/udev/rules.d/*.rules; then
  printf 'SUBSYSTEM=="i2c-dev", KERNEL=="i2c-[0-9]*", ATTRS{class}=="0x030000", TAG+="uaccess"\n' \
    | sudo tee /etc/udev/rules.d/60-ddcutil-i2c.rules >/dev/null
fi

sudo modprobe i2c-dev
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=i2c-dev --action=add
sudo udevadm settle
ddcutil detect
noctalia msg config-reload
printf 'DDC/CI discovery enabled. Open Noctalia’s control center to check each display.\n'
