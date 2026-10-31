#!/usr/bin/env bash
# ============================================================
# ZyraxonOS — auto-update + AI guard units.
#
#   install.sh <rootfs>
#
# Installs the systemd units that keep ZYRAXON AI current and pinned.
# ============================================================
set -uo pipefail
ROOT="${1:?usage: install.sh <rootfs>}"
HERE="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$ROOT/etc/systemd/system" "$ROOT/var/lib/zyraxon" \
         "$ROOT/var/cache/zyraxon" "$ROOT/usr/local/bin"
install -m 0755 "$HERE/zyraxon-ota" "$ROOT/usr/local/bin/zyraxon-ota"

cat > "$ROOT/etc/systemd/system/zyraxon-update.service" <<'UNIT'
[Unit]
Description=ZyraxonOS auto-update check
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/python3 /opt/zyraxon/zyraxon-update.py --once
UNIT

cat > "$ROOT/etc/systemd/system/zyraxon-update.timer" <<'UNIT'
[Unit]
Description=Check for ZyraxonOS and ZYRAXON AI updates

[Timer]
OnBootSec=2min
OnUnitActiveSec=6h
Persistent=true

[Install]
WantedBy=timers.target
UNIT

cat > "$ROOT/etc/systemd/system/zyraxon-guard.service" <<'UNIT'
[Unit]
Description=ZyraxonOS AI guard (keep ZYRAXON AI installed)
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/opt/zyraxon/zyraxon-guard.sh
UNIT

cat > "$ROOT/etc/systemd/system/zyraxon-guard.timer" <<'UNIT'
[Unit]
Description=Run the ZyraxonOS AI guard

[Timer]
OnBootSec=1min
OnUnitActiveSec=1h
Persistent=true

[Install]
WantedBy=timers.target
UNIT

chroot "$ROOT" bash -c '
  systemctl enable zyraxon-update.timer zyraxon-guard.timer >/dev/null 2>&1 || true
' || true
