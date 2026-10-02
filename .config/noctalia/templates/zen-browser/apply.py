#!/usr/bin/env python3
"""Add Noctalia CSS imports to existing Zen profiles, preserving other settings."""

import configparser
import fcntl
import json
import os
from pathlib import Path
import re
import tempfile


def write_changed(path, content):
    if path.exists() and path.read_text() == content:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    mode = path.stat().st_mode & 0o777 if path.exists() else 0o600
    with tempfile.NamedTemporaryFile(mode='w', dir=path.parent, prefix='.'+path.name, delete=False) as stream:
        temp = Path(stream.name)
        stream.write(content)
    try:
        temp.chmod(mode)
        temp.replace(path)
    finally:
        temp.unlink(missing_ok=True)


def main():
    home = Path.home()
    config = Path(os.environ.get('XDG_CONFIG_HOME', home/'.config'))
    cache = Path(os.environ.get('XDG_CACHE_HOME', home/'.cache'))/'noctalia/zen-browser'
    sheets = {name: cache/('zen-'+name) for name in ['userChrome.css', 'userContent.css']}
    # The second template hook installs both imports once both renders exist.
    if not all(path.is_file() for path in sheets.values()):
        return
    with (cache/'apply.lock').open('w') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        profiles = set()
        for root in [config/'zen', home/'.zen']:
            ini = configparser.ConfigParser(interpolation=None)
            ini.read(root/'profiles.ini')
            for section in ini.sections():
                if section.startswith('Profile') and ini.has_option(section, 'Path'):
                    path = Path(ini[section]['Path'])
                    if ini.getboolean(section, 'IsRelative', fallback=True):
                        path = root/path
                    if (path/'prefs.js').is_file():
                        profiles.add(path.resolve())
        for profile in sorted(profiles):
            for name, sheet in sheets.items():
                target = profile/'chrome'/name
                previous = target.read_text() if target.exists() else ''
                lines = [line for line in previous.splitlines(keepends=True)
                         if not (line.lstrip().startswith('@import') and 'zen-browser/zen-'+name in line)]
                write_changed(target, '@import '+json.dumps(str(sheet))+';\n'+''.join(lines))
            target = profile/'user.js'
            previous = target.read_text() if target.exists() else ''
            key = 'toolkit.legacyUserProfileCustomizations.stylesheets'
            text = re.sub(r'^\s*user_pref\(\s*[\"\']'+re.escape(key)+r'[\"\'].*?;[^\n]*\n?', '', previous, flags=re.M)
            if text and not text.endswith('\n'):
                text += '\n'
            write_changed(target, text+'user_pref('+json.dumps(key)+', true);\n')


if __name__ == '__main__':
    main()
