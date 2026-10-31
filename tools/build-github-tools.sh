#!/bin/bash
# ============================================================
# ZyraxonOS — build/install the tools that Debian does not package.
#
# Debian ships most of the 600-tool set, but a few live only upstream on
# GitHub (nuclei, subfinder, ffuf, termshark, airgeddon, responder,
# wifiphisher, evilginx2). This script compiles the Go ones and wires the
# script/Python ones onto PATH, so the ISO is fully self-contained and the
# user never has to download anything.
#
# Safe to run repeatedly.
# ============================================================
set -u
LOG=/var/log/zyraxon-github.log
SRC=/opt/zyraxon-tools
say() { printf '\n\033[1;36m[zyraxon-github]\033[0m %s\n' "$*"; }

export DEBIAN_FRONTEND=noninteractive
export GOFLAGS=-mod=mod
export GOPROXY="${GOPROXY:-https://proxy.golang.org,direct}"
export CGO_ENABLED=0

build_go() {  # name  relative-build-target
  local name="$1" target="$2"
  if [ -x "/usr/local/bin/$name" ]; then say "$name already installed"; return 0; fi
  if [ ! -d "$SRC/$name" ]; then say "skip $name (source missing)"; return 0; fi
  say "building $name"
  if ( cd "$SRC/$name" && go build -o "/usr/local/bin/$name" "$target" ) >>"$LOG" 2>&1; then
    say "$name installed"
  else
    say "$name build failed (see $LOG)"
  fi
}

wrap() {  # name  command-line
  local name="$1"; shift
  printf '#!/bin/sh\nexec %s "$@"\n' "$*" > "/usr/local/bin/$name"
  chmod +x "/usr/local/bin/$name"
  say "$name wrapper installed"
}

say "building the upstream-only toolset"

build_go nuclei    ./cmd/nuclei
build_go subfinder ./cmd/subfinder
build_go ffuf      .
build_go termshark ./cmd/termshark

# evilginx2 is a Go project with a Makefile.
if [ -d "$SRC/evilginx2" ]; then
  say "building evilginx2"
  if ( cd "$SRC/evilginx2" && make ) >>"$LOG" 2>&1; then
    [ -x "$SRC/evilginx2/build/evilginx" ] && cp "$SRC/evilginx2/build/evilginx" /usr/local/bin/evilginx
    say "evilginx installed"
  else
    say "evilginx2 build failed (see $LOG)"
  fi
fi

# Script / Python tools: thin wrappers so the names resolve on PATH.
[ -f "$SRC/airgeddon/airgeddon.sh" ] && { chmod +x "$SRC/airgeddon/airgeddon.sh"; wrap airgeddon "$SRC/airgeddon/airgeddon.sh"; }
[ -f "$SRC/responder/Responder.py" ] && { chmod +x "$SRC/responder/Responder.py"; wrap responder "python3 $SRC/responder/Responder.py"; }
if [ -f "$SRC/wifiphisher/bin/wifiphisher" ]; then
  chmod +x "$SRC/wifiphisher/bin/wifiphisher"; wrap wifiphisher "python3 $SRC/wifiphisher/bin/wifiphisher"
elif [ -d "$SRC/wifiphisher" ]; then
  wrap wifiphisher "python3 -m wifiphisher"
fi

say "upstream toolset done — log: $LOG"

# The Go module/build caches are only needed while compiling; dropping them
# keeps the image small.
rm -rf /root/go /root/.cache/go-build 2>/dev/null || true
