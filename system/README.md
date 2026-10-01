# Optional system settings

Requires an existing greetd + Noctalia Greeter setup. These templates are not installed automatically.

Replace `@USER@` in `noctalia-greeter/greeter.toml`. Back up the existing `/etc/greetd/config.toml` and `/var/lib/noctalia-greeter/` before deploying; greeter state must be readable by its account. `sync.toml` is an initial fallback, replaced by desktop appearance sync.

```bash
sudo timedatectl set-timezone Asia/Amman
sudo noctalia-greeter passwordless-sync enable "$USER"
```

Change the desktop wallpaper to trigger sync. Apply service changes at your next boot.
