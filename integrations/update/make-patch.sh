#!/usr/bin/env bash
# ============================================================
# ZyraxonOS — build a small OTA patch between two releases.
#
#   make-patch.sh <old-rootfs> <new-rootfs> <from-ver> <to-ver> [outdir]
#
# Produces zyraxon-patch-<from>-to-<to>.tar.zst containing only the files
# that differ, plus a .sha256 and a .files manifest. Upload the three files
# to the GitHub release and every running ZyraxonOS can pull just the diff —
# no reinstall.
# ============================================================
set -uo pipefail

OLD="${1:?usage: make-patch.sh <old-rootfs> <new-rootfs> <from> <to> [outdir]}"
NEW="${2:?}"
FROM="${3:?}"
TO="${4:?}"
OUT="${5:-$(pwd)}"

NAME="zyraxon-patch-${FROM}-to-${TO}.tar.zst"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

say(){ printf '\033[1;36m[make-patch]\033[0m %s\n' "$*"; }

say "diffing $OLD -> $NEW"
# Skip volatile, machine-local and kernel paths that must not be patched live.
cd "$NEW"
find . -xdev \
  -path ./proc -prune -o -path ./sys -prune -o -path ./dev -prune -o \
  -path ./run -prune -o -path ./tmp -prune -o -path ./boot -prune -o \
  -path ./var/log -prune -o -path ./var/cache -prune -o \
  -path ./var/lib/zyraxon -prune -o -path ./etc/.git -prune -o \
  -path ./home -prune -o -path ./root -prune -o \
  -type f -print 2>/dev/null >"$WORK/new.list"

: >"$WORK/changed.list"
while IFS= read -r f; do
  o="$OLD/${f#./}"
  if [ ! -e "$o" ] || ! cmp -s "$o" "$f"; then
    printf '%s\n' "${f#./}" >>"$WORK/changed.list"
  fi
done <"$WORK/new.list"

say "changed files: $(wc -l <"$WORK/changed.list")"
tar --zstd -cf "$OUT/$NAME" -C "$NEW" -T "$WORK/changed.list"
( cd "$OUT" && sha256sum "$NAME" >"$NAME.sha256" )
cp "$WORK/changed.list" "$OUT/$NAME.files"

say "wrote $OUT/$NAME ($(du -h "$OUT/$NAME" | cut -f1))"
say "upload $NAME, $NAME.sha256 and $NAME.files to the release"
