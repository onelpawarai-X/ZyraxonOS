#!/usr/bin/env bash
# ============================================================
# ZyraxonOS — install the pinned ZYRAXON AI desktop agent.
#
#   install.sh <rootfs> [version]
#
# Downloads the pinned .deb from the ZYRAXON-AI GitHub release and
# installs it into <rootfs>. The .deb is cached so repeat builds do
# not hit the network again.
# ============================================================
set -uo pipefail

ROOT="${1:?usage: install.sh <rootfs> [version]}"
VERSION="${2:-19.0.9}"
REPO="onelpawarai-X/ZYRAXON-AI"
DEB="zyraxon-desktop-linux-amd64.deb"
CACHE="$(cd "$(dirname "$0")/../.." && pwd)/cache"
LOG="$ROOT/var/log/zyraxon-tools.log"

say(){ printf '\033[1;36m[zyraxon-ai]\033[0m %s\n' "$*"; }

mkdir -p "$CACHE" "$ROOT/opt/zyraxon" "$ROOT/var/log"
: >>"$LOG"

URL="https://github.com/${REPO}/releases/download/v${VERSION}/${DEB}"
if [ ! -s "$CACHE/$DEB" ]; then
  say "downloading ZYRAXON AI ${VERSION}"
  curl -fL --retry 3 --retry-delay 2 -o "$CACHE/$DEB.part" "$URL" \
    && mv "$CACHE/$DEB.part" "$CACHE/$DEB" \
    || { say "download failed — AI will be installed on first boot"; rm -f "$CACHE/$DEB.part"; }
fi

if [ -s "$CACHE/$DEB" ]; then
  cp "$CACHE/$DEB" "$ROOT/tmp/zyraxon-ai.deb"
  chroot "$ROOT" bash -c '
    export DEBIAN_FRONTEND=noninteractive
    apt-get install -y --no-install-recommends /tmp/zyraxon-ai.deb >>/var/log/zyraxon-tools.log 2>&1 \
      || dpkg -i /tmp/zyraxon-ai.deb >>/var/log/zyraxon-tools.log 2>&1 \
      || true
    rm -f /tmp/zyraxon-ai.deb
  '
  echo "$VERSION" > "$ROOT/opt/zyraxon/.installed-version"
  say "ZYRAXON AI ${VERSION} installed and pinned"
else
  say "skipped (no cached package)"
fi

# The guard + auto-updater ship inside the image so the agent can never be
# removed and always stays current.
HERE="$(cd "$(dirname "$0")" && pwd)"
cp "$HERE/guard.sh"  "$ROOT/opt/zyraxon/zyraxon-guard.sh"
cp "$HERE/update.py" "$ROOT/opt/zyraxon/zyraxon-update.py"
chmod 0755 "$ROOT/opt/zyraxon/zyraxon-guard.sh" "$ROOT/opt/zyraxon/zyraxon-update.py"
