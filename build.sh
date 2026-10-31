#!/usr/bin/env bash
# ============================================================
# ZyraxonOS build - debootstrap + real XFCE desktop + glass theme
#
#   sudo bash build.sh
#
# Steps: base system -> real desktop environment -> ZyraxonOS
# glass theme and configs -> live initramfs -> squashfs -> hybrid ISO
# ============================================================
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$HERE/rootfs"
ISO_DIR="$HERE/iso"
OUT="$HERE/ZyraxonOS-1.0-amd64.iso"
MIRROR="http://deb.debian.org/debian"
SUITE="trixie"

say() { printf '\n\033[1;36m[zyraxon]\033[0m %s\n' "$*"; }
die() { printf '\n\033[1;31m[error]\033[0m %s\n' "$*"; exit 1; }

[[ $EUID -eq 0 ]] || die "run as root (sudo)"

# ---------- 1. base system ----------
if [[ ! -d "$ROOT/etc" ]]; then
  say "debootstrap $SUITE -> $ROOT"
  mkdir -p "$ROOT"
  debootstrap --arch=amd64 --variant=minbase --include=ca-certificates \
    "$SUITE" "$ROOT" "$MIRROR" || die "debootstrap failed"
else
  say "reusing existing base at $ROOT"
fi

# ---------- 2. chroot plumbing ----------
say "mounting pseudo filesystems"
mount --bind /dev "$ROOT/dev" 2>/dev/null || true
mount -t proc proc "$ROOT/proc" 2>/dev/null || true
mount --bind /sys "$ROOT/sys" 2>/dev/null || true
mkdir -p "$ROOT/dev/pts"
mount -t devpts devpts "$ROOT/dev/pts" 2>/dev/null || true
cp -f /etc/resolv.conf "$ROOT/etc/resolv.conf" 2>/dev/null || \
  echo "nameserver 1.1.1.1" > "$ROOT/etc/resolv.conf"

cleanup() {
  for d in dev/pts dev proc sys; do umount -lf "$ROOT/$d" 2>/dev/null || true; done
}
trap cleanup EXIT

# ---------- 3. package install inside the chroot ----------
say "writing package lists into the chroot"
mkdir -p "$ROOT/tmp/pkgs"
cp "$HERE"/config/package-lists/*.list.chroot "$ROOT/tmp/pkgs/" 2>/dev/null || true

cat > "$ROOT/tmp/install.sh" <<'INNER'
#!/bin/bash
set -uo pipefail
export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C

cat > /etc/apt/sources.list <<'SRC'
deb http://deb.debian.org/debian trixie main contrib non-free non-free-firmware
deb http://deb.debian.org/debian trixie-updates main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware
SRC
rm -f /etc/apt/sources.list.d/* 2>/dev/null || true
apt-get update -qq

echo "[inner] installing core system"
apt-get install -y --no-install-recommends \
  linux-image-amd64 initramfs-tools \
  live-boot live-config live-config-systemd live-tools \
  systemd systemd-sysv dbus dbus-x11 udev \
  locales console-setup kbd tzdata \
  sudo adduser apt-utils gnupg rsync less nano \
  dosfstools ntfs-3g exfatprogs e2fsprogs xfsprogs btrfs-progs \
  parted gdisk lvm2 cryptsetup util-linux usbutils pciutils \
  firmware-linux-free firmware-iwlwifi firmware-realtek 2>&1 | tail -2

echo "[inner] installing the real desktop environment (XFCE)"
apt-get install -y \
  xfce4 xfce4-goodies xfce4-whiskermenu-plugin \
  xfce4-pulseaudio-plugin xfce4-clipman-plugin xfce4-notifyd \
  xfce4-power-manager xfce4-screenshooter xfce4-settings \
  xfce4-terminal thunar thunar-archive-plugin thunar-volman \
  mousepad ristretto xfce4-taskmanager 2>&1 | tail -2

echo "[inner] installing display stack + compositor"
apt-get install -y --no-install-recommends \
  xserver-xorg xserver-xorg-core xserver-xorg-video-all \
  xserver-xorg-input-all xinit x11-utils x11-xserver-utils xauth \
  xdotool wmctrl picom compton \
  libgl1-mesa-dri mesa-utils \
  lightdm lightdm-gtk-greeter 2>&1 | tail -2

echo "[inner] installing theming + fonts"
apt-get install -y --no-install-recommends \
  gtk2-engines gtk2-engines-murrine gtk2-engines-pixbuf gtk3-engines-xfce \
  libglib2.0-bin sassc \
  fonts-dejavu fonts-dejavu-core fonts-dejavu-extra \
  fonts-noto fonts-noto-core fonts-noto-color-emoji \
  fonts-liberation fonts-cantarell fonts-font-awesome \
  adwaita-icon-theme papirus-icon-theme hicolor-icon-theme dmz-cursor-theme \
  xdg-utils xdg-user-dirs 2>&1 | tail -2

echo "[inner] installing audio"
apt-get install -y --no-install-recommends \
  pipewire pipewire-pulse wireplumber alsa-utils pavucontrol 2>&1 | tail -2

echo "[inner] installing applications"
apt-get install -y --no-install-recommends \
  firefox-esr chromium \
  libreoffice-writer libreoffice-calc libreoffice-impress libreoffice-gtk3 \
  evince poppler-utils \
  vlc rhythmbox mpv ffmpeg sox imagemagick gimp inkscape \
  file-roller p7zip-full zip unzip xz-utils zstd \
  geany python3 python3-pip python3-venv git curl wget \
  gnome-disk-utility gparted htop ncdu tree mc screen tmux \
  bash-completion command-not-found man-db manpages \
  network-manager network-manager-gnome nm-connection-editor \
  openssh-client cups system-config-printer ghostscript \
  gnome-software gnome-software-plugin-flatpak flatpak 2>&1 | tail -2

echo "[inner] installing security toolset"
apt-get install -y --no-install-recommends \
  nmap masscan aircrack-ng hashcat john hydra sqlmap \
  tshark dsniff ettercap-text-only macchanger reaver pixiewps \
  mdk4 hcxdumptool crunch socat tcpdump whatweb gobuster dirb wfuzz \
  bettercap wifite netcat-openbsd bully cowpatty hping3 arping \
  dnsutils whois traceroute iftop nethogs bmon iptraf-ng 2>&1 | tail -2

apt-get clean
rm -rf /var/lib/apt/lists/*
echo "[inner] package installation complete"
INNER
chmod +x "$ROOT/tmp/install.sh"

say "installing packages inside the chroot (this takes a while)"
chroot "$ROOT" /tmp/install.sh || say "some packages failed - continuing"

# ---------- 4. ZyraxonOS configs ----------
say "installing the ZyraxonOS glass theme and configs"
cp -a "$HERE/config/includes.chroot/." "$ROOT/" 2>/dev/null || true

say "running the branding hook"
for hook in "$HERE"/config/hooks/live/*zyraxon*.hook.chroot; do
  [ -f "$hook" ] || continue
  cp "$hook" "$ROOT/tmp/hook.sh"
  chmod +x "$ROOT/tmp/hook.sh"
  chroot "$ROOT" /tmp/hook.sh || say "hook reported an issue"
  rm -f "$ROOT/tmp/hook.sh"
done

# ---------- 5. initramfs ----------
say "rebuilding the initramfs with live-boot + overlay support"
printf 'overlay\nsquashfs\nloop\ndm_mod\n' > "$ROOT/etc/initramfs-tools/modules"
sed -i 's/^MODULES=.*/MODULES=most/' "$ROOT/etc/initramfs-tools/initramfs.conf" 2>/dev/null || true
chroot "$ROOT" update-initramfs -u -k all 2>&1 | tail -2 || true

# ---------- 6. squashfs ----------
say "packing the live filesystem"
mkdir -p "$ISO_DIR/live"
for d in dev proc sys run tmp; do mkdir -p "$ROOT/$d"; done
rm -f "$ISO_DIR/live/filesystem.squashfs"
mksquashfs "$ROOT" "$ISO_DIR/live/filesystem.squashfs" \
  -comp xz -b 1M -noappend -processors 2 -e boot >/dev/null || die "mksquashfs failed"

KVER="$(ls "$ROOT/boot" | grep -oP 'vmlinuz-\K.*' | sort -V | tail -1)"
say "kernel: $KVER"
cp "$ROOT/boot/vmlinuz-$KVER"    "$ISO_DIR/live/vmlinuz"
cp "$ROOT/boot/initrd.img-$KVER" "$ISO_DIR/live/initrd.img"

# ---------- 7. boot menus ----------
say "writing the boot menus"
mkdir -p "$ISO_DIR/isolinux"
cp /usr/lib/ISOLINUX/isolinux.bin "$ISO_DIR/isolinux/"
for f in ldlinux.c32 libcom32.c32 libutil.c32 menu.c32 vesamenu.c32; do
  cp "/usr/lib/syslinux/modules/bios/$f" "$ISO_DIR/isolinux/" 2>/dev/null || true
done
cat > "$ISO_DIR/isolinux/isolinux.cfg" <<'CFG'
UI vesamenu.c32
MENU TITLE ZyraxonOS 1.0 - Glass Edition
TIMEOUT 50
PROMPT 0
DEFAULT zyraxon

LABEL zyraxon
  MENU LABEL ^Start ZyraxonOS 1.0 (Glass Edition)
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
cat > "$ISO_DIR/boot/grub/grub.cfg" <<'CFG'
set timeout=5
set default=0
insmod all_video
insmod gfxterm
set gfxmode=1440x900,1280x800,1024x768,auto
terminal_output gfxterm

menuentry "Start ZyraxonOS 1.0 (Glass Edition)" {
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
dd if=/dev/zero of="$EFIIMG" bs=1M count=4 status=none
mkfs.vfat "$EFIIMG" >/dev/null
mmd -i "$EFIIMG" ::/EFI ::/EFI/BOOT
mcopy -i "$EFIIMG" "$ISO_DIR/EFI/boot/bootx64.efi" ::/EFI/BOOT/BOOTX64.EFI

# ---------- 8. ISO ----------
say "assembling $OUT"
rm -f "$OUT"
xorriso -as mkisofs \
  -iso-level 3 -full-iso9660-filenames \
  -volid "ZYRAXONOS" \
  -p "ZyraxonOS 1.0" -publisher "ZyraxonOS" -A "ZyraxonOS 1.0 amd64" \
  -eltorito-boot isolinux/isolinux.bin \
  -eltorito-catalog isolinux/boot.cat \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot \
  -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
  -isohybrid-gpt-basdat \
  -output "$OUT" "$ISO_DIR" || die "xorriso failed"

say "ISO ready: $OUT  ($(du -h "$OUT" | cut -f1))"
file "$OUT"
