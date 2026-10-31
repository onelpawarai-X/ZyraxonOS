#!/usr/bin/env bash
set -uo pipefail
HERE=/workspace/zyraxonos-build; ISO_DIR="$HERE/iso"; OUT="$HERE/ZyraxonOS-1.0-amd64.iso"
rm -f "$OUT"
xorriso -as mkisofs -iso-level 3 -full-iso9660-filenames -volid "ZYRAXONOS" \
  -p "ZyraxonOS 1.0" -publisher "ZyraxonOS" -A "ZyraxonOS 1.0 amd64" \
  -eltorito-boot isolinux/isolinux.bin -eltorito-catalog isolinux/boot.cat \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot \
  -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
  -isohybrid-gpt-basdat -output "$OUT" "$ISO_DIR" && \
  echo "ISO ready: $OUT ($(du -h "$OUT" | cut -f1))"
