#!/usr/bin/env bash
set -uo pipefail
HERE=/workspace/zyraxonos-build
ROOT="$HERE/rootfs"; ISO_DIR="$HERE/iso"; OUT="$HERE/ZyraxonOS-1.0-amd64.iso"
say(){ printf '\n\033[1;36m[zyraxon]\033[0m %s\n' "$*"; }
for d in dev/pts dev proc sys; do umount -lf "$ROOT/$d" 2>/dev/null || true; done
say "packing the live filesystem"
for d in dev proc sys run tmp; do mkdir -p "$ROOT/$d"; done
rm -f "$ISO_DIR/live/filesystem.squashfs"
mksquashfs "$ROOT" "$ISO_DIR/live/filesystem.squashfs" -comp zstd -Xcompression-level 19 -b 1M -noappend -processors 1 -e boot >/dev/null || exit 1
KVER="$(ls "$ROOT/boot" | grep -oP 'vmlinuz-\K.*' | sort -V | tail -1)"
cp "$ROOT/boot/vmlinuz-$KVER" "$ISO_DIR/live/vmlinuz"
cp "$ROOT/boot/initrd.img-$KVER" "$ISO_DIR/live/initrd.img"
say "assembling $OUT"
rm -f "$OUT"
xorriso -as mkisofs -iso-level 3 -full-iso9660-filenames -volid "ZYRAXONOS" \
  -p "ZyraxonOS 1.0" -publisher "ZyraxonOS" -A "ZyraxonOS 1.0 amd64" \
  -eltorito-boot isolinux/isolinux.bin -eltorito-catalog isolinux/boot.cat \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot \
  -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
  -isohybrid-gpt-basdat -output "$OUT" "$ISO_DIR" || exit 1
say "ISO ready: $OUT ($(du -h "$OUT" | cut -f1))"
