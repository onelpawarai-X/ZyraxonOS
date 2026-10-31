<p align="center">
  <img src="docs/banner.png" width="100%" alt="ZyraxonOS">
</p>

<h1 align="center">ZyraxonOS</h1>

<p align="center"><b>The most powerful operating system.</b><br>
A glass-morphism Linux desktop, built from the ground up, with the ZYRAXON AI
agent permanently built in.</p>

---

## What it is

ZyraxonOS is a complete, bootable operating system. It boots to a real desktop
with a real window manager, real applications and a real package base — then
lays an ultra-translucent glass layer over all of it: a floating centred
taskbar, a glass start menu, glass notifications, glass settings and a glass
context menu on every right-click.

Nothing here is a mockup. It is a full Linux system image you can write to a USB
stick and boot on real hardware.

## Highlights

| | |
|---|---|
| **Desktop** | Real XFCE session, glass-themed end to end |
| **Glass everywhere** | Taskbar, start menu, notifications, settings, dialogs, context menus |
| **Centred taskbar** | Floating, scrollable, drag it left or right |
| **Start menu** | Whisker menu, glass panel, live search |
| **Settings** | Accent colour, wallpaper, glass blur and transparency, branding |
| **Built-in AI** | ZYRAXON AI agent, permanently installed, auto-updating |
| **Tool set** | 600+ power tools plus a purpose-built Wi-Fi / security collection |
| **Updates** | OS and AI updates arrive as glass notifications |
| **Base** | Debian, live-boot, hybrid BIOS + UEFI image |

## Download

Grab the latest image from the [Releases](../../releases) page:

```
ZyraxonOS-1.0-amd64.iso
```

Write it to a USB stick:

```bash
sudo dd if=ZyraxonOS-1.0-amd64.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

It is a hybrid image: BIOS and UEFI machines both boot it, and it also runs
directly in a virtual machine:

```bash
qemu-system-x86_64 -m 3072 -smp 2 -cdrom ZyraxonOS-1.0-amd64.iso -boot d
```

## Repository layout

```
build.sh                     full build: rootfs, glass layer, squashfs, ISO
rebuild-iso.sh               repack the ISO after changing the desktop
config/
  package-lists/             the exact package set that goes into the image
  includes.chroot/           the glass desktop that is baked into the system
    usr/share/themes/ZyraxonGlass/   GTK2 + GTK3 + xfwm4 glass theme
    etc/xdg/picom.conf               compositor: real background blur
    usr/share/backgrounds/           the Aurora wallpaper
    usr/local/bin/zyraxon-settings   the ZyraxonOS control centre
    etc/skel/.config/xfce4/          panel, window manager, session defaults
  hooks/live/                build-time customisation (branding, session)
boot-test.py                 headless QEMU boot test with screenshots
docs/                        screenshots and notes
```

## Building from source

```bash
sudo apt-get install -y debootstrap squashfs-tools xorriso isolinux \
  syslinux-common syslinux-efi grub-pc-bin grub-efi-amd64-bin mtools \
  dosfstools qemu-system-x86
sudo bash build.sh
```

The result is `ZyraxonOS-1.0-amd64.iso`.

## Design

Every surface is a translucent glass chip. Panels, windows, buttons, inputs,
menus and notifications are all frosted glass over a live animated background.
The compositor does the real blur, so the effect holds over any application.

## License

See [LICENSE](LICENSE). Base system packages keep their own licenses.
