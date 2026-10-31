# AGENTS.md — ZyraxonOS build notes

## What this repository is

The reproducible source for **ZyraxonOS 9.0.0 (Glass Edition)** — a real
Debian-based live OS whose desktop is the ZyraxonOS glass shell on Hyprland.
`build.sh` builds `rootfs/` and `rebuild-iso.sh` packs the hybrid ISO.
`rootfs/` and `iso/` are build artifacts and are git-ignored.

## Build

```bash
sudo bash build.sh          # full build: rootfs + toolset + AI + ISO
sudo bash rebuild-iso.sh    # fast repack of an existing rootfs
```

Both run as root. `rebuild-iso.sh` needs `rootfs/` to exist.

## Layout

- `config/dots/` — the desktop (Hyprland + quickshell). Deployed to
  `/usr/share/zyraxonos/dots` and `/etc/skel` by the branding hook.
- `config/hooks/live/0100-zyraxon-branding.hook.chroot` — branding + deploy.
- `tools/` — `core-600.txt`, `wifi-50.txt`, `custom-50.txt`, `package-map.txt`,
  `install-tools.sh` (the only copy; `integrations/tools` was a duplicate).
- `integrations/zyraxon/` — `install.sh` (pins the ZYRAXON AI `.deb`),
  `guard.sh` (re-pins it), `update.py` (release watcher).
- `integrations/update/` — `zyraxon-ota` (in-place updater), `make-patch.sh`
  (builds the small diff patch), `install.sh` (systemd units).

## Toolset rules (do not regress)

- `apt_install()` must check `apt-cache policy <p>` for a real `Candidate:`
  (not `(none)`) and fall back to per-package installs. A single virtual
  name like `awk` once dropped a whole 40-package batch.
- Never run pip with `--ignore-installed`: it shadows Debian packages in
  `/usr/local/lib/python3/dist-packages` and breaks system tools such as
  `borgbackup`, `duplicity` and `python3-openssl`.
- `etckeeper` hangs for many minutes on `/etc/.git` during its postinst.
  It is not needed on a live image; the install survives the hang but it
  wastes time.
- `mpvpaper` (animated wallpapers) is not in Debian and is built from
  source by `build.sh`.
- `zx-*` is one dispatcher (`tools/zx`) plus symlinks; `zx help` lists all.

## Branding rules

The name must be **ZyraxonOS** everywhere. No `illogical-impulse`,
`end-4`, `dots-hyprland` or `ILLOGICAL_IMPULSE_VIRTUAL_ENV` anywhere in
source, configs, comments or translations. The venv env var is
`ZYRAXON_VIRTUAL_ENV`.

## Updating

`zyraxon-ota` has two channels: `patch` (small `.tar.zst` of changed files,
no reinstall) and `full` (unpack the ISO over `/`). `make-patch.sh`
produces the patch + `.sha256` + `.files` manifest to upload to a release.
