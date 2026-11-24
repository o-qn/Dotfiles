#!/usr/bin/env python3
"""Copy this desktop snapshot with backups. Never installs packages or root settings."""
import argparse
import datetime
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent
CONFIG_DIRS = (
    'umbriel',
    'niri',
    'hypr',
    'noctalia',
    'luciole',
    'xdg-desktop-portal',
    'kitty',
    'alacritty',
    'fish',
    'fastfetch',
    'nemo',
    'btop',
    'qt6ct',
    'nvim',
)


def targets(home):
    bin_dir = ROOT / '.local/bin'
    nemo_actions_dir = ROOT / '.local/share/nemo/actions'
    return [home / '.config' / name for name in CONFIG_DIRS] + [
        home / '.config/dolphinrc',
        home / '.config/easyeffectsrc',
        *[home / '.local/bin' / p.name for p in sorted(bin_dir.iterdir()) if p.is_file()],
        *[home / '.local/share/nemo/actions' / p.name for p in sorted(nemo_actions_dir.iterdir()) if p.is_file()],
        home / '.local/share/noctalia/plugins/displays',
        home / '.local/share/noctalia/plugins/umbriel-layout',
        home / '.local/state/noctalia/settings.toml',
        *[home / '.local/share/wallpapers' / p.name for p in sorted((ROOT / '.local/share/wallpapers').iterdir())],
    ]


def expand(text, home):
    for token, path in {'@CONFIG_HOME@': home / '.config', '@DATA_HOME@': home / '.local/share',
                        '@HOME@': home, '@USER@': home.name}.items():
        text = text.replace(token, str(path))
    return text


def deploy(home):
    for source in sorted(ROOT.rglob('*')):
        relative = source.relative_to(ROOT)
        if relative.parts[0] not in {'.config', '.local'} or not source.is_file():
            continue
        target = home / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        if target.is_symlink():
            target.unlink()
        if source.name in {'dolphinrc', 'easyeffectsrc'} or source.suffix in {'.toml', '.conf', '.lua', '.py', '.sh'}:
            target.write_text(expand(source.read_text(), home))
            shutil.copymode(source, target)
        else:
            shutil.copy2(source, target)


def symlink(home):
    for target in targets(home):
        source = ROOT / target.relative_to(home)
        target.parent.mkdir(parents=True, exist_ok=True)
        remove(target)
        target.symlink_to(source)


def remove(path):
    if path.is_symlink() or path.is_file():
        path.unlink()
    elif path.is_dir():
        shutil.rmtree(path)


def backup(home):
    stamp = datetime.datetime.now().astimezone().strftime('%Y%m%d-%H%M%S-%f')
    folder = home / '.local/state/desktop-dotfiles/backups' / stamp
    folder.mkdir(parents=True, mode=0o700)
    entries = []
    for i, target in enumerate(targets(home)):
        saved = f'files/{i}'
        exists = target.exists() or target.is_symlink()
        entries.append({'path': str(target), 'saved': saved, 'existed': exists})
        if exists:
            destination = folder / saved
            destination.parent.mkdir(parents=True, exist_ok=True)
            if target.is_symlink():
                destination.symlink_to(os.readlink(target))
            elif target.is_dir():
                shutil.copytree(target, destination, symlinks=True)
            else:
                shutil.copy2(target, destination)
    (folder / 'manifest.json').write_text(json.dumps({'paths': entries}, indent=2) + '\n')
    return folder


def restore(folder):
    entries = json.loads((folder / 'manifest.json').read_text())['paths']
    for entry in reversed(entries):
        target = Path(entry['path'])
        remove(target)
        if entry['existed']:
            source = folder / entry['saved']
            target.parent.mkdir(parents=True, exist_ok=True)
            if source.is_symlink():
                target.symlink_to(os.readlink(source))
            elif source.is_dir():
                shutil.copytree(source, target, symlinks=True)
            else:
                shutil.copy2(source, target)
    print(f'Restored: {folder}')


def validate():
    if not shutil.which('noctalia'):
        raise SystemExit('Missing noctalia; install desktop dependencies first.')
    if not any(shutil.which(command) for command in ('umbriel', 'niri', 'Hyprland')):
        raise SystemExit('Missing umbriel (or niri / Hyprland); install desktop dependencies first.')
    with tempfile.TemporaryDirectory(prefix='desktop-dotfiles-check-') as directory:
        home = Path(directory)
        deploy(home)
        if shutil.which('umbriel'):
            subprocess.run(['umbriel', 'config', 'validate', '-c', str(home / '.config/umbriel/config.toml')], check=True)
        if shutil.which('niri'):
            subprocess.run(['niri', 'validate', '-c', str(home / '.config/niri/config.kdl')], check=True)
        if shutil.which('Hyprland'):
            env = dict(os.environ, HYPR_CONFIG_ROOT=str(home / '.config/hypr'))
            subprocess.run(['Hyprland', '--verify-config', '-c', str(home / '.config/hypr/hyprland.lua')], env=env, check=True)
        result = subprocess.run(['noctalia', 'config', 'validate', str(home / '.config/noctalia/config.toml')], capture_output=True, text=True, check=True)
        print(result.stdout, end='')
        if 'WARN ' in result.stdout + result.stderr:
            raise SystemExit(result.stdout + result.stderr)
    print('Portable configuration validated. Live settings were not changed.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group()
    group.add_argument('--check', action='store_true', help='Validate in a temporary directory')
    group.add_argument('--dry-run', action='store_true', help='List targets without changing anything')
    group.add_argument('--restore', type=Path, metavar='BACKUP', help='Restore a previous backup')
    parser.add_argument('--symlink', action='store_true', help='Symlink tracked targets to this repo instead of copying')
    parser.add_argument('--target-home', type=Path, default=Path.home(), help='Installation home (default: current user)')
    args = parser.parse_args()
    home = args.target_home.expanduser().resolve()
    if args.restore:
        restore(args.restore.expanduser().resolve())
        return
    if args.check:
        validate()
        return
    if args.dry_run:
        action = 'symlink' if args.symlink else 'copy'
        print(f'Would back up and {action}:')
        for target in targets(home):
            print(f'  {target}')
        print('GUI preferences are in the base config; existing Noctalia overrides are backed up and reset.')
        print('No packages, system settings, Git operations, or services are changed.')
        return
    if os.geteuid() == 0:
        raise SystemExit('Run as your desktop user, without sudo.')
    if os.environ.get('XDG_CONFIG_HOME') or os.environ.get('XDG_DATA_HOME') or os.environ.get('XDG_STATE_HOME'):
        raise SystemExit('This installer targets standard ~/.config and ~/.local paths; unset custom XDG paths first.')
    validate()
    saved = backup(home)
    try:
        if args.symlink:
            symlink(home)
        else:
            # Replace directory symlinks only after backing up the link itself.
            for target in targets(home):
                if target.is_symlink():
                    target.unlink()
            deploy(home)
    except Exception:
        restore(saved)
        raise
    verb = 'Symlinked' if args.symlink else 'Installed'
    print(f'{verb} configuration for {home}. Backup: {saved}')
    print('No services were restarted. Log in to Umbriel (or Niri / Hyprland), then run scripts/apply-theme.sh.')
    print(f'Rollback: python3 install.py --restore {saved}')


if __name__ == '__main__':
    main()
