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
  local pkgs=() p cand
  for p in "$@"; do
    # Already installed? skip — never re-resolve 600 names every run.
    if dpkg-query -W -f='${Status}' "$p" 2>/dev/null | grep -q "install ok installed"; then
      continue
    fi
    # A real candidate must exist; virtual packages report "(none)".
    cand="$(apt-cache policy "$p" 2>/dev/null | awk '/Candidate:/{print $2; exit}')"
    if [ -n "$cand" ] && [ "$cand" != "(none)" ]; then pkgs+=("$p"); fi
  done
  [ ${#pkgs[@]} -eq 0 ] && return 0
  # Batch as big as possible: apt resolves the whole set in one shot.
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    "${pkgs[@]}" >>"$LOG" 2>&1 && return 0
  # A single unsatisfiable name must not drop the batch: drop it and retry.
  local bad
  bad="$(grep -aoE "Package '[^']+' has no installation candidate|E: Unable to locate package [^ ]+" "$LOG" | tail -1)"
  if [ -n "$bad" ]; then
    local drop; drop="$(printf '%s' "$bad" | sed -E "s/.*'([^']+)'.*/\1/; s/.*package //")"
    local keep=()
    for p in "${pkgs[@]}"; do [ "$p" = "$drop" ] || keep+=("$p"); done
    if [ ${#keep[@]} -gt 0 ] && [ ${#keep[@]} -lt ${#pkgs[@]} ]; then
      DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        "${keep[@]}" >>"$LOG" 2>&1 || true
    fi
  fi
}

# pip tooling for the Python tools Debian does not package.
# Never --ignore-installed: pip must respect the Debian packages that
# share these modules, or the system Python breaks.
pip_install() {
  local py=/usr/bin/python3
  [ -x "$py" ] || return 0
  DEBIAN_FRONTEND=noninteractive "$py" -m pip install --break-system-packages \
    --no-input -q "$@" >>"$LOG" 2>&1 || true
}

npm_install() {
  command -v npm >/dev/null 2>&1 || return 0
  npm install -g --silent "$@" >>"$LOG" 2>&1 || true
}

# ---------------- core: 600 tools ----------------
if [ "$DO_CORE" = 1 ]; then
  say "installing the 600 built-in Linux power tools"
  mapfile -t CORE < <(grep -vE '^\s*#|^\s*$' "$HERE/core-600.txt")
  say "resolving ${#CORE[@]} names against apt"
  apt-get update >>"$LOG" 2>&1 || true

  # apply the name->package corrections, dropping entries mapped to "-"
  declare -A MAP=()
  if [ -f "$HERE/package-map.txt" ]; then
    while IFS='|' read -r from to; do
      from="$(echo "$from" | tr -d ' ')"; to="$(echo "$to" | tr -d ' ')"
      [ -z "$from" ] && continue
      MAP["$from"]="$to"
    done < <(grep -vE '^\s*#|^\s*$' "$HERE/package-map.txt")
  fi

  batch=(); i=0
  for p in "${CORE[@]}"; do
    if [ -n "${MAP[$p]+x}" ]; then
      [ "${MAP[$p]}" = "-" ] && continue
      p="${MAP[$p]}"
    fi
    batch+=("$p"); i=$((i+1))
    if [ $((i % 40)) -eq 0 ]; then apt_install "${batch[@]}"; batch=(); fi
  done
  [ ${#batch[@]} -gt 0 ] && apt_install "${batch[@]}"

  # the Python and Node tools Debian does not ship
  say "installing the Python tooling that Debian does not package"
  pip_install pytest coverage hypothesis freezegun tenacity rich textual \
    safety pip-audit semgrep pyright pexpect paramiko urwid inquirer
  say "installing the Node tooling that Debian does not package"
  npm_install pnpm bun
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
          # Never block the build on one slow clone: time it out and fall
          # back to a tarball download.
          if ! timeout 120 git clone --depth 1 "https://github.com/$repo.git" "$dest" >>"$LOG" 2>&1; then
            rm -rf "$dest"
            if timeout 120 curl -fL --retry 2 --connect-timeout 20 \
                 -o "/tmp/$name.tar.gz" "https://codeload.github.com/$repo/tar.gz/HEAD" >>"$LOG" 2>&1; then
              mkdir -p "$dest"
              tar -xzf "/tmp/$name.tar.gz" -C "$dest" --strip-components=1 >>"$LOG" 2>&1 || true
              rm -f "/tmp/$name.tar.gz"
            else
              say "could not fetch $name from $repo (skipped)"
            fi
          fi
          [ -f "$dest/setup.sh" ]   && timeout 300 bash "$dest/setup.sh"   >>"$LOG" 2>&1 || true
          [ -f "$dest/install.sh" ] && timeout 300 bash "$dest/install.sh" >>"$LOG" 2>&1 || true
        fi ;;
    esac
  done < <(grep -vE '^\s*#|^\s*$' "$HERE/wifi-50.txt")
  say "wifi/security toolset done (see /opt/zyraxon-tools)"
fi

say "toolset installation finished — log: $LOG"

# keep the image small
apt-get clean >>"$LOG" 2>&1 || true
rm -rf /var/lib/apt/lists/* >>"$LOG" 2>&1 || true
