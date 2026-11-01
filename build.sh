#!/usr/bin/env bash
# ============================================================
# ZyraxonOS build — debootstrap + Hyprland glass desktop
#
#   sudo bash build.sh
#
# Steps: base system -> Hyprland/quickshell glass desktop ->
# ZyraxonOS branding and configs -> live initramfs -> squashfs ->
# hybrid BIOS/UEFI ISO.
#
# The desktop is the ZyraxonOS glass shell, vendored
# under config/dots and deployed by the branding hook.
# ============================================================
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$HERE/rootfs"
ISO_DIR="$HERE/iso"
VERSION="9.0.0"
OUT="$HERE/ZyraxonOS-${VERSION}-amd64.iso"
MIRROR="http://deb.debian.org/debian"
SUITE="trixie"
BACKPORTS="trixie-backports"

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

cat > "$ROOT/tmp/install.sh" <<INNER
#!/bin/bash
set -uo pipefail
export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C

cat > /etc/apt/sources.list <<'SRC'
deb http://deb.debian.org/debian trixie main contrib non-free non-free-firmware
deb http://deb.debian.org/debian trixie-updates main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware
deb http://deb.debian.org/debian ${BACKPORTS} main contrib non-free non-free-firmware
SRC
rm -f /etc/apt/sources.list.d/* 2>/dev/null || true
apt-get update -qq

echo "[inner] installing core system"
apt-get install -y --no-install-recommends \
  linux-image-amd64 initramfs-tools \
  live-boot live-config live-config-systemd live-tools \
  systemd systemd-sysv dbus dbus-x11 udev seatd \
  locales console-setup kbd tzdata \
  sudo adduser apt-utils gnupg rsync less nano \
  dosfstools ntfs-3g exfatprogs e2fsprogs xfsprogs btrfs-progs \
  parted gdisk lvm2 cryptsetup util-linux usbutils pciutils \
  firmware-linux-free firmware-iwlwifi firmware-realtek 2>&1 | tail -2

echo "[inner] installing the Hyprland glass desktop (Wayland)"
apt-get install -y -t ${BACKPORTS} --no-install-recommends \
  hyprland hyprpaper hypridle hyprlock hyprpicker hyprsunset \
  quickshell waybar wofi fuzzel 2>&1 | tail -2

echo "[inner] installing Qt6 / QML runtime"
apt-get install -y --no-install-recommends \
  qt6-wayland qt6ct qt6-svg-plugins libqt6svg6 \
  qml6-module-qtquick qml6-module-qtquick-controls qml6-module-qtquick-layouts \
  qml6-module-qtquick-window qml6-module-qtquick-templates qml6-module-qtquick-effects \
  qml6-module-qtquick-shapes qml6-module-qtquick-dialogs \
  qml6-module-qt5compat-graphicaleffects qml6-module-qtqml \
  qml6-module-qtqml-models qml6-module-qtqml-workerscript \
  qml6-module-qt-labs-folderlistmodel qml6-module-qt-labs-qmlmodels \
  qml6-module-org-kde-kirigami qml6-module-org-kde-syntaxhighlighting 2>&1 | tail -2

echo "[inner] installing the glass shell bits"
apt-get install -y --no-install-recommends \
  dunst kitty foot thunar wlogout swaybg grim slurp wl-clipboard cliphist \
  wtype ydotool brightnessctl playerctl polkit-kde-agent-1 cava qalc \
  translate-shell libqalculate23 ffmpeg upower libdbusmenu-gtk3-4 2>&1 | tail -2

echo "[inner] installing theming + fonts"
apt-get install -y --no-install-recommends \
  gtk2-engines gtk2-engines-murrine gtk2-engines-pixbuf \
  libglib2.0-bin sassc \
  fontconfig fonts-font-awesome fonts-noto-color-emoji fonts-inter \
  fonts-jetbrains-mono fonts-dejavu fonts-noto-core fonts-liberation \
  adwaita-icon-theme papirus-icon-theme hicolor-icon-theme dmz-cursor-theme \
  xdg-utils xdg-user-dirs xdg-desktop-portal xdg-desktop-portal-hyprland \
  xdg-desktop-portal-gtk 2>&1 | tail -2

echo "[inner] installing audio"
apt-get install -y --no-install-recommends \
  pipewire pipewire-pulse wireplumber alsa-utils pavucontrol 2>&1 | tail -2

echo "[inner] installing applications"
apt-get install -y --no-install-recommends \
  firefox-esr libreoffice-writer libreoffice-calc libreoffice-impress libreoffice-gtk3 \
  evince poppler-utils \
  mpv ffmpeg imagemagick \
  file-roller p7zip-full zip unzip xz-utils zstd \
  geany python3 python3-pip python3-venv python3-numpy python3-pil \
  python3-requests python3-gi python3-cairo python3-psutil python3-opencv \
  python3-click python3-tqdm python3-cryptography python3-google-auth \
  python3-dbus python3-setuptools \
  git curl wget jq socat bc ripgrep \
  gnome-disk-utility gparted htop ncdu tree mc screen tmux \
  bash-completion command-not-found man-db manpages \
  network-manager network-manager-gnome nm-connection-editor \
  openssh-client cups system-config-printer ghostscript 2>&1 | tail -2

echo "[inner] building the quickshell python environment"
mkdir -p /home/zyraxon/.local/state/quickshell
python3 -m venv --system-site-packages /home/zyraxon/.local/state/quickshell/.venv
/home/zyraxon/.local/state/quickshell/.venv/bin/pip install --upgrade pip -q 2>&1 | tail -1
/home/zyraxon/.local/state/quickshell/.venv/bin/pip install -q \
  materialyoucolor==2.0.10 material-color-utilities==0.2.1 \
  pywayland==0.4.18 libsass==0.23.0 loguru==0.7.3 setproctitle==1.3.4 2>&1 | tail -2

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

# the ZyraxonOS glass shell, vendored in config/dots
say "deploying the glass desktop config (config/dots)"
mkdir -p "$ROOT/usr/share/zyraxonos"
rm -rf "$ROOT/usr/share/zyraxonos/dots"
cp -a "$HERE/config/dots" "$ROOT/usr/share/zyraxonos/dots"

# the ZyraxonOS toolset: 600 built-in tools + zx-* + wifi/security
say "installing the built-in toolset (600+ tools)"
mkdir -p "$ROOT/usr/share/zyraxonos/tools"
cp -a "$HERE/tools/." "$ROOT/usr/share/zyraxonos/tools/"
chmod +x "$ROOT/usr/share/zyraxonos/tools/install-tools.sh"
chroot "$ROOT" /usr/share/zyraxonos/tools/install-tools.sh --all \
  || say "toolset reported an issue (non-fatal)"

# fill in the names that map to a different Debian package, plus the
# PyPI-only tools
say "filling in the mapped + PyPI toolset"
chroot "$ROOT" /usr/share/zyraxonos/tools/fill-tools.sh \
  || say "fill step reported an issue (non-fatal)"

# the tools that only live upstream on GitHub (nuclei, subfinder, ffuf,
# termshark, airgeddon, responder, wifiphisher, evilginx2)
say "building the upstream-only (GitHub) tools"
chroot "$ROOT" /usr/share/zyraxonos/tools/build-github-tools.sh \
  || say "github tool build reported an issue (non-fatal)"

# animated (video) wallpapers need mpvpaper, which Debian does not package
say "building mpvpaper (animated wallpaper support)"
if ! chroot "$ROOT" bash -c 'command -v mpvpaper >/dev/null 2>&1'; then
  chroot "$ROOT" bash -c '
    export DEBIAN_FRONTEND=noninteractive
    apt-get install -y --no-install-recommends \
      git meson ninja-build wayland-protocols libwayland-dev libmpv-dev \
      pkg-config libmpv2 >>/var/log/zyraxon-tools.log 2>&1 || true
    rm -rf /tmp/mpvpaper
    git clone --depth 1 https://github.com/GhostNaN/mpvpaper /tmp/mpvpaper \
      >>/var/log/zyraxon-tools.log 2>&1 || true
    if [ -d /tmp/mpvpaper ]; then
      cd /tmp/mpvpaper
      meson setup build --prefix=/usr >>/var/log/zyraxon-tools.log 2>&1 || true
      ninja -C build >>/var/log/zyraxon-tools.log 2>&1 || true
      ninja -C build install >>/var/log/zyraxon-tools.log 2>&1 || true
    fi
    rm -rf /tmp/mpvpaper
  ' || say "mpvpaper build skipped (animated wallpapers will be unavailable)"
fi

say "installing the built-in ZYRAXON AI agent"
bash "$HERE/integrations/zyraxon/install.sh" "$ROOT" "${ZYRAXON_AI_VERSION:-19.0.9}" \
  || say "AI install reported an issue (non-fatal)"

say "installing the auto-update + AI guard units"
bash "$HERE/integrations/update/install.sh" "$ROOT" \
  || say "update units reported an issue (non-fatal)"

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
  -comp zstd -Xcompression-level 19 -b 1M -noappend -processors 2 -e boot \
  >/dev/null || die "mksquashfs failed"

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

# ---------- 8. ISO ----------
say "assembling $OUT"
rm -f "$OUT"
xorriso -as mkisofs \
  -iso-level 3 -full-iso9660-filenames \
  -volid "ZYRAXONOS" \
  -p "ZyraxonOS ${VERSION}" -publisher "ZyraxonOS" -A "ZyraxonOS ${VERSION} amd64" \
  -eltorito-boot isolinux/isolinux.bin \
  -eltorito-catalog isolinux/boot.cat \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot \
  -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
  -isohybrid-gpt-basdat \
  -output "$OUT" "$ISO_DIR" || die "xorriso failed"

say "ISO ready: $OUT  ($(du -h "$OUT" | cut -f1))"
file "$OUT"
