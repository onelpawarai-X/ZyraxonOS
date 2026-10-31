# ZyraxonOS 9.0.0 — Glass Edition

A live Linux operating system with a **glass-morphism** desktop, built on
Debian GNU/Linux, with the **ZYRAXON AI** agent permanently installed and a
full security toolkit baked in.

ZyraxonOS boots straight into a translucent glass desktop: real GPU blur,
frosted panels, animated windows and a floating glass top bar — no login
required. It runs from a USB stick or a virtual machine and never touches
your disk.

## Highlights

- **Real glass desktop** — Hyprland (Wayland) with GPU blur, vibrancy,
  rounded corners, drop shadows and smooth animations on every window.
- **Glass top bar** — a floating translucent Waybar with workspaces, clock,
  system tray, audio, network, Bluetooth and battery.
- **Glass launcher and notifications** — Wofi launcher and Dunst toasts,
  both frosted.
- **ZYRAXON AI, permanently built in** — the latest ZYRAXON AI release is
  installed at build time, pinned and locked. It cannot be removed, and the
  auto-update daemon keeps it current.
- **Auto-update system** — a daemon watches the ZyraxonOS and ZYRAXON AI
  releases and pushes an update notice to every running desktop as a glass
  toast.
- **Power toolkit** — 600 built-in Linux power tools, 50 custom `zx-*`
  tools written for this OS, and 50 Wi-Fi / network / security tools.
- **Fully themeable** — wallpaper, accent colour, glass blur and
  transparency are all changeable at runtime.

## Download

Grab the latest ISO from the [Releases](../../releases) page:

```
ZyraxonOS-9.0.0-amd64.iso
```

Write it to a USB stick and boot it:

```bash
sudo dd if=ZyraxonOS-9.0.0-amd64.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

It is a hybrid image: it boots on BIOS and UEFI machines, and also runs
directly in a virtual machine.

## Try it without installing

```bash
qemu-system-x86_64 -m 3072 -smp 2 -cdrom ZyraxonOS-9.0.0-amd64.iso -boot d
```

## Keyboard shortcuts

| Key | Action |
| --- | --- |
| `Super` + `Enter` | Terminal (kitty) |
| `Super` + `D` | App launcher (wofi) |
| `Super` + `E` | File manager |
| `Super` + `Q` | Close window |
| `Super` + `F` | Fullscreen |
| `Super` + `L` | Lock screen |
| `Super` + `1…5` | Switch workspace |
| `Super` + `Shift` + `1…5` | Move window to workspace |
| `Super` + `Shift` + `S` | Screenshot a region |
| `Super` + `V` | Clipboard history |

## The `zx-*` tools

Fifty tools written for ZyraxonOS, all behind one dispatcher:

```bash
zx help              # list everything
zx sysinfo           # hardware + OS + network summary
zx wifi-scan         # scan nearby Wi-Fi networks
zx net-scan          # fast LAN discovery
zx sec-audit         # system security audit
zx ai-status         # is the ZYRAXON AI agent installed and healthy?
zx update            # check for OS + AI updates now
```

## Layout

```
shell/            the glass desktop (HTML/CSS/JS reference implementation)
server/           shell backend and the safe terminal endpoint
config/           Hyprland, Waybar, Wofi, Dunst, Kitty and wallpaper
  hypr/           hyprland.lua, hyprpaper.conf
  skel/           everything that lands in /etc/skel
  session/        the desktop session launcher
integrations/     ZYRAXON AI, the auto-update daemon and the tool sets
  zyraxon/        install + update + guard
  tools/          600-tool manifest, 50 custom tools, 50 Wi-Fi tools
  update/         OS + AI auto-update
build.sh, rebuild-iso.sh   the reproducible ISO build
                            (rootfs + hybrid ISO)
branding/         boot splash and brand assets
docs/             architecture and notes
```

## Building from source

```bash
sudo apt-get install -y debootstrap squashfs-tools xorriso isolinux \
  syslinux-common syslinux-efi grub-pc-bin grub-efi-amd64-bin mtools \
  dosfstools qemu-system-x86

# build the root filesystem, then the ISO
sudo bash build.sh
sudo bash rebuild-iso.sh
```

The result is `ZyraxonOS-9.0.0-amd64.iso`.

## Design rules

Every surface is a translucent glass chip: panels, windows, bars, menus and
notifications all use GPU blur over a live animated background. Nothing is
opaque.

## License

See [LICENSE](LICENSE). Base system packages remain under their own
licenses (Debian GNU/Linux).
