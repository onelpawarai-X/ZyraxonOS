#!/usr/bin/env bash
# ============================================================
# ZyraxonOS — ZYRAXON AI guard.
#
# Pins the agent so it can never be uninstalled, then re-installs it
# if anything ever removes it. Run from a systemd timer and from
# `zx ai-guard`.
# ============================================================
set -uo pipefail
LOG=/var/log/zyraxon-tools.log
VERSION_FILE=/opt/zyraxon/.installed-version

log(){ printf '[zyraxon-guard] %s\n' "$*" | tee -a "$LOG"; }

# Which package did we install?
PKG=""
for p in zyraxon-desktop zyraxon; do
  if dpkg -s "$p" >/dev/null 2>&1; then PKG="$p"; break; fi
done

if [ -n "$PKG" ]; then
  apt-mark hold "$PKG" >/dev/null 2>&1 || true
  log "pinned $PKG (held)"
else
  log "ZYRAXON AI package missing — attempting restore"
  deb="$(ls /var/cache/zyraxon/*.deb 2>/dev/null | head -1)"
  if [ -n "$deb" ]; then
    dpkg -i "$deb" >>"$LOG" 2>&1 || true
    log "restored from $deb"
  else
    log "no local package to restore from"
  fi
fi

log "version: $(cat "$VERSION_FILE" 2>/dev/null || echo unknown)"
