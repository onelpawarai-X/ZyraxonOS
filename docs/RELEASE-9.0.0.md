## ZyraxonOS 9.0.0 — Glass Edition

The most powerful operating system. A live Linux OS with a real
glass-morphism desktop, built on Debian GNU/Linux, with the ZYRAXON AI
agent permanently installed and a full security toolkit baked in.

### What's new in 9.0.0

- **Real glass desktop.** Hyprland (Wayland) replaces the old XFCE shell.
  Every window has GPU blur, vibrancy, 22px rounded corners, drop shadows
  and smooth spring animations.
- **Floating glass top bar.** A translucent Waybar with workspaces, clock,
  system tray, audio, network, Bluetooth, battery and a power button.
- **Glass launcher and toasts.** Wofi launcher and Dunst notifications,
  both frosted.
- **New Aurora wallpaper** and a matching glass accent palette.

### ZYRAXON AI, built in permanently

The latest ZYRAXON AI release is installed into the image at build time,
then pinned and locked so it cannot be removed. A background daemon keeps
it up to date and shows an update toast on the desktop whenever a new
release is published.

### Auto-update

An update daemon watches both repositories:

- `onelpawarai-X/ZyraxonOS` — new OS releases
- `onelpawarai-X/ZYRAXON-AI` — new AI agent builds

When something new appears, every running desktop gets a glass
notification.

### Toolkit

- **600** built-in Linux power tools
- **50** custom `zx-*` tools written for ZyraxonOS
- **50** Wi-Fi, network and security tools (Kali set)

```bash
zx help              # list every tool
zx sysinfo           # hardware + OS + network summary
zx wifi-scan         # scan nearby Wi-Fi networks
zx sec-audit         # system security audit
zx ai-status         # ZYRAXON AI health
zx update            # check for OS + AI updates now
```

### Theme it your way

Wallpaper, accent colour, glass blur and panel transparency are all
changeable at runtime from the desktop.

### Download

```
ZyraxonOS-9.0.0-amd64.iso
```

Hybrid image: boots on BIOS and UEFI, and runs in a virtual machine.

```bash
sudo dd if=ZyraxonOS-9.0.0-amd64.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

### Verify

```
SHA256: 12bca1bbb7b51b9b73e6bf5fd2da51837f2733749fb26aeedc5f229fdd1050b0
```

Built on Debian GNU/Linux. Live session — nothing is written to your disk.
