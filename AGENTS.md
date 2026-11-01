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

## Glass shell (quickshell) rules (do not regress)

The `ii` shell must load with no `Failed to load configuration` errors.
Three things made it fail silently on boot and leave the desktop bare:

- `config/dots/.../modules/common/widgets/shapes/` must keep the full
  module tree (`ShapeCanvas.qml`, `material-shapes.js`, `qmldir`,
  `geometry/`, `graphics/`, and the nested `shapes/*.js`). `RectangularShadow`
  and `MaterialShape` import it; if it is missing every widget that uses
  `StyledRectangularShadow` fails.
- `modules/common/widgets/RectangularShadow.qml` must be **world-readable**
  (mode 644). A file created as 600 makes quickshell report
  `RectangularShadow is not a type` and the whole shell fails to load.
  Check with `find config/dots -not -perm -o=r`.
- The five files using `DelegateChooser`/`TableModel` need
  `import Qt.labs.qmlmodels`, and `build.sh` must install
  `qml6-module-qt-labs-qmlmodels` (the plugin also needs the
  `libQt6LabsQmlModels.so.6` library that ships in the same package).

Verify quickly in QEMU: log in, then
`qs -c ii 2>&1 | grep -c "Failed to load configuration"` must print `0`.

## Branding rules

The name must be **ZyraxonOS** everywhere. No `illogical-impulse`,
`end-4`, `dots-hyprland` or `ILLOGICAL_IMPULSE_VIRTUAL_ENV` anywhere in
source, configs, comments or translations. The venv env var is
`ZYRAXON_VIRTUAL_ENV`.

## Releases and distribution

- GitHub caps a single release asset at 2 GiB (`size must be less than
  2147483648`), so the 6.0 GB ISO is attached as `part_00..part_03`
  (2 000 000 000 bytes each); rejoin with
  `cat part_00 part_01 part_02 part_03 > ZyraxonOS-9.0.0-amd64.iso`.
  `REJOIN.txt` and `SHA256SUMS.txt` are attached alongside.
- The release body carries a direct link to the **whole** ISO on Hugging
  Face plus the SHA-256. 9.0.0 ISO:
  `https://huggingface.co/datasets/sayidi12/ZyraxonOS/resolve/main/ZyraxonOS-9.0.0-amd64.iso`,
  sha256 `222f43ee97918ff224794a9bef1ad62252e2339dc6616df9696a6f8362883013`
  (6 006 325 248 bytes). Upload with `HfApi(token=...).upload_file(...,
  repo_type='dataset')`.
- The ISO is built from `rootfs/` with `mksquashfs -comp zstd
  -Xcompression-level 15` + `xorriso` (see `rebuild-iso.sh`). Build it on a
  filesystem with >= 15 GB free; `/workspace` (25 GB, rootfs 19 GB) is too
  tight for both the squashfs and the ISO, so build in `/opt`.
- After any repack, refresh `SHA256SUMS.txt`, re-split, and re-upload the
  parts, or the published checksum will not match.

## Updating

`zyraxon-ota` has two channels: `patch` (small `.tar.zst` of changed files,
no reinstall) and `full` (unpack the ISO over `/`). `make-patch.sh`
produces the patch + `.sha256` + `.files` manifest to upload to a release.
