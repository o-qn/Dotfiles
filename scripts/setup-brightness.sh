#!/usr/bin/env bash
set -euo pipefail
# Run as your desktop user. Only the package/module/udev steps require sudo.
sudo pacman -S --needed ddcutil
sudo modprobe i2c-dev
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=i2c-dev --action=add
sudo udevadm settle
# Arch's ddcutil package includes the boot module entry and uaccess device rules.
ddcutil detect
noctalia msg config-reload
printf 'DDC/CI discovery enabled. Open Noctalia’s control center to check each display.\n'
