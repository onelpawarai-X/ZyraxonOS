#!/usr/bin/env bash
# ============================================================
# ZyraxonOS — repack the live filesystem and rebuild the ISO.
#
#   sudo bash rebuild-iso.sh
#
# Assumes rootfs/ already exists (see build.sh). This is the fast
# path used after changing configs: squashfs -> kernel/initrd ->
# hybrid BIOS/UEFI ISO.
# ============================================================
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$HERE/rootfs"
ISO_DIR="$HERE/iso"
VERSION="9.0.0"
OUT="$HERE/ZyraxonOS-${VERSION}-amd64.iso"

say(){ printf '\n\033[1;36m[zyraxon]\033[0m %s\n' "$*"; }
die(){ printf '\n\033[1;31m[error]\033[0m %s\n' "$*"; exit 1; }

[[ $EUID -eq 0 ]] || die "run as root (sudo)"

for d in dev/pts dev proc sys; do umount -lf "$ROOT/$d" 2>/dev/null || true; done

say "packing the live filesystem"
for d in dev proc sys run tmp; do mkdir -p "$ROOT/$d"; done
mkdir -p "$ISO_DIR/live"
rm -f "$ISO_DIR/live/filesystem.squashfs"
mksquashfs "$ROOT" "$ISO_DIR/live/filesystem.squashfs" \
  -comp zstd -Xcompression-level 19 -b 1M -noappend -processors 2 -e boot \
  >/dev/null || die "mksquashfs failed"

KVER="$(ls "$ROOT/boot" | grep -oP 'vmlinuz-\K.*' | sort -V | tail -1)"
say "kernel: $KVER"
cp "$ROOT/boot/vmlinuz-$KVER"    "$ISO_DIR/live/vmlinuz"
cp "$ROOT/boot/initrd.img-$KVER" "$ISO_DIR/live/initrd.img"

say "writing the boot menus"
mkdir -p "$ISO_DIR/isolinux"
cp /usr/lib/ISOLINUX/isolinux.bin "$ISO_DIR/isolinux/"
for f in ldlinux.c32 libcom32.c32 libutil.c32 menu.c32 vesamenu.c32; do
  cp "/usr/lib/syslinux/modules/bios/$f" "$ISO_DIR/isolinux/" 2>/dev/null || true
done
cat > "$ISO_DIR/isolinux/isolinux.cfg" <<CFG
UI vesamenu.c32
MENU TITLE ZyraxonOS ${VERSION} - Glass Edition
TIMEOUT 50
PROMPT 0
DEFAULT zyraxon

LABEL zyraxon
  MENU LABEL ^Start ZyraxonOS ${VERSION} (Glass Edition)
  KERNEL /live/vmlinuz
  APPEND initrd=/live/initrd.img boot=live components quiet splash console=tty0
  TEXT HELP
  Boot the ZyraxonOS glass desktop.
  ENDTEXT

LABEL safe
  MENU LABEL ZyraxonOS (^safe graphics)
  KERNEL /live/vmlinuz
  APPEND initrd=/live/initrd.img boot=live components nomodeset console=tty0
  TEXT HELP
  Use this if the graphics card is not supported.
  ENDTEXT
CFG

mkdir -p "$ISO_DIR/boot/grub/fonts" "$ISO_DIR/EFI/boot"
cp /usr/share/grub/unicode.pf2 "$ISO_DIR/boot/grub/fonts/" 2>/dev/null || true
cat > "$ISO_DIR/boot/grub/grub.cfg" <<CFG
set timeout=5
set default=0
insmod all_video
insmod gfxterm
set gfxmode=1440x900,1280x800,1024x768,auto
terminal_output gfxterm

menuentry "Start ZyraxonOS ${VERSION} (Glass Edition)" {
  linux  /live/vmlinuz boot=live components quiet splash console=tty0
  initrd /live/initrd.img
}
menuentry "ZyraxonOS (safe graphics)" {
  linux  /live/vmlinuz boot=live components nomodeset console=tty0
  initrd /live/initrd.img
}
CFG
grub-mkstandalone --format=x86_64-efi \
  --output="$ISO_DIR/EFI/boot/bootx64.efi" --locales="" --fonts="" \
  "boot/grub/grub.cfg=$ISO_DIR/boot/grub/grub.cfg" 2>/dev/null || true
EFIIMG="$ISO_DIR/boot/grub/efi.img"
rm -f "$EFIIMG"
dd if=/dev/zero of="$EFIIMG" bs=1M count=8 status=none
mkfs.vfat "$EFIIMG" >/dev/null
mmd -i "$EFIIMG" ::/EFI ::/EFI/BOOT
mcopy -i "$EFIIMG" "$ISO_DIR/EFI/boot/bootx64.efi" ::/EFI/BOOT/BOOTX64.EFI

say "assembling $OUT"
rm -f "$OUT"
xorriso -as mkisofs -iso-level 3 -full-iso9660-filenames -volid "ZYRAXONOS" \
  -p "ZyraxonOS ${VERSION}" -publisher "ZyraxonOS" -A "ZyraxonOS ${VERSION} amd64" \
  -eltorito-boot isolinux/isolinux.bin -eltorito-catalog isolinux/boot.cat \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot \
  -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
  -isohybrid-gpt-basdat -output "$OUT" "$ISO_DIR" || die "xorriso failed"

say "ISO ready: $OUT ($(du -h "$OUT" | cut -f1))"
file "$OUT"
