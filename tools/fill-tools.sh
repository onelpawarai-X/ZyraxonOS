#!/bin/bash
# ============================================================
# ZyraxonOS — fill in the toolset names that map to a different
# Debian package name, or that ship on PyPI instead of apt.
# Runs after install-tools.sh; safe to run repeatedly.
# ============================================================
set -u
LOG=/var/log/zyraxon-fill.log
say() { printf '\n\033[1;36m[zyraxon-fill]\033[0m %s\n' "$*"; }
export DEBIAN_FRONTEND=noninteractive

# Names in the 600 list that Debian ships under a different package name.
say "installing name-mapped Debian packages"
for p in \
  bsdmainutils bind9-dnsutils exim4-daemon-light cpufrequtils tlp ntpsec \
  kismet mitmproxy radare2 salt-minion snort unetbootin netdata abduco s6 \
  exfatprogs zfsutils-linux ; do
  apt-get install -y --no-install-recommends "$p" >>"$LOG" 2>&1 \
    && say "ok: $p" || say "skipped: $p"
done

# Python tools that live on PyPI rather than in Debian. --ignore-installed
# keeps pip from trying to remove the Debian-provided copies of shared
# modules (that is what breaks the system Python).
say "installing the PyPI toolset"
pip3 install --no-input --break-system-packages --ignore-installed -q \
  ruff mock freezegun tenacity rich textual pexpect paramiko fabric \
  plumbum shellingham termcolor urwid npyscreen inquirer \
  >>"$LOG" 2>&1 && say "pip toolset ok" || say "pip toolset had issues"

# pip can drop a stray metadata dir that shadows Debian's click; drop it so
# the system click keeps working.
rm -rf /usr/lib/python3/dist-packages/click-0.5.2.egg-info 2>/dev/null || true

say "fill done — log: $LOG"
