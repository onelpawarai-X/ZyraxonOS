#!/usr/bin/env bash
# ============================================================
# ZyraxonOS toolset installer
#
#   install-tools.sh [--core] [--custom] [--wifi] [--all]
#
#   --core    600 built-in Linux power tools (apt)
#   --custom  the 50 ZyraxonOS "zx-*" tools (written for this OS)
#   --wifi    the 50 Wi-Fi / network / security tools (apt + upstream git)
#   --all     everything
#
# Safe to run repeatedly. Missing packages are skipped, not fatal.
# ============================================================
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
BIN=/usr/local/bin
LOG=/var/log/zyraxon-tools.log
say() { printf '\n\033[1;36m[zyraxon-tools]\033[0m %s\n' "$*"; }

DO_CORE=0; DO_CUSTOM=0; DO_WIFI=0
[ $# -eq 0 ] && DO_CUSTOM=1
for a in "$@"; do
  case "$a" in
    --core) DO_CORE=1;; --custom) DO_CUSTOM=1;; --wifi) DO_WIFI=1;;
    --all) DO_CORE=1; DO_CUSTOM=1; DO_WIFI=1;;
  esac
done

apt_install() {  # install whatever exists, ignore the rest
  local pkgs=() p
  for p in "$@"; do apt-cache show "$p" >/dev/null 2>&1 && pkgs+=("$p"); done
  [ ${#pkgs[@]} -eq 0 ] && return 0
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    "${pkgs[@]}" >>"$LOG" 2>&1 || true
}

# ---------------- core: 600 tools ----------------
if [ "$DO_CORE" = 1 ]; then
  say "installing the 600 built-in Linux power tools"
  mapfile -t CORE < <(grep -vE '^\s*#|^\s*$' "$HERE/core-600.txt")
  say "resolving ${#CORE[@]} names against apt"
  apt-get update >>"$LOG" 2>&1 || true
  batch=(); i=0
  for p in "${CORE[@]}"; do
    batch+=("$p"); i=$((i+1))
    if [ $((i % 40)) -eq 0 ]; then apt_install "${batch[@]}"; batch=(); fi
  done
  [ ${#batch[@]} -gt 0 ] && apt_install "${batch[@]}"
  say "core toolset done"
fi

# ---------------- custom: 50 zx-* tools ----------------
if [ "$DO_CUSTOM" = 1 ]; then
  say "installing the 50 ZyraxonOS zx-* tools"
  mkdir -p "$BIN"
  install -m 0755 "$HERE/zx" "$BIN/zx"
  n=0
  while IFS='|' read -r name _desc; do
    name="$(echo "$name" | tr -d ' ')"
    [ -z "$name" ] && continue
    ln -sf zx "$BIN/$name"; n=$((n+1))
  done < <(grep -vE '^\s*#|^\s*$' "$HERE/custom-50.txt")
  say "installed $n zx-* tools (dispatcher: zx help)"
fi

# ---------------- wifi / security: 50 tools ----------------
if [ "$DO_WIFI" = 1 ]; then
  say "installing the 50 Wi-Fi / network / security tools"
  mkdir -p /opt/zyraxon-tools
  while IFS='|' read -r name src; do
    name="$(echo "$name" | tr -d ' ')"; src="$(echo "$src" | tr -d ' ')"
    [ -z "$name" ] && continue
    case "$src" in
      apt) apt_install "$name" ;;
      github:*)
        repo="${src#github:}"; dest="/opt/zyraxon-tools/$name"
        if [ ! -d "$dest" ]; then
          git clone --depth 1 "https://github.com/$repo.git" "$dest" >>"$LOG" 2>&1 || true
          [ -f "$dest/setup.sh" ]   && bash "$dest/setup.sh"   >>"$LOG" 2>&1 || true
          [ -f "$dest/install.sh" ] && bash "$dest/install.sh" >>"$LOG" 2>&1 || true
        fi ;;
    esac
  done < <(grep -vE '^\s*#|^\s*$' "$HERE/wifi-50.txt")
  say "wifi/security toolset done (see /opt/zyraxon-tools)"
fi

say "toolset installation finished — log: $LOG"
