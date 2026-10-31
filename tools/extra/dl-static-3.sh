#!/bin/bash
DL=/workspace/tool-dl3; BIN=/workspace/ZyraxonOS/rootfs/usr/local/bin
mkdir -p "$DL" "$BIN"; cd "$DL"; ok=0; fail=0
get(){ n="$1"; u="$2"; k="$3"; f="$DL/$(basename "$u")"
  if ! curl -fsSL --retry 2 --connect-timeout 20 -o "$f" "$u"; then echo "FAIL-DL $n"; fail=$((fail+1)); return; fi
  case "$k" in
    raw) install -m755 "$f" "$BIN/$n" ;;
    gz)  gunzip -c "$f" > "$BIN/$n" && chmod 755 "$BIN/$n" ;;
    tgz) rm -rf "$DL/x_$n"; mkdir -p "$DL/x_$n"; tar -xzf "$f" -C "$DL/x_$n"
         b=$(find "$DL/x_$n" -type f -name "$n" | head -1); [ -z "$b" ] && b=$(find "$DL/x_$n" -maxdepth 3 -type f -perm -u+x ! -name "*.txt" ! -name "LICENSE*" ! -name "*.md" | head -1)
         [ -n "$b" ] && install -m755 "$b" "$BIN/$n" || { echo "FAIL-EXTRACT $n"; fail=$((fail+1)); return; } ;;
    zip) rm -rf "$DL/x_$n"; mkdir -p "$DL/x_$n"; unzip -oq "$f" -d "$DL/x_$n"
         b=$(find "$DL/x_$n" -type f -name "$n" | head -1); [ -z "$b" ] && b=$(find "$DL/x_$n" -type f -perm -u+x | head -1)
         [ -n "$b" ] && install -m755 "$b" "$BIN/$n" || { echo "FAIL-EXTRACT $n"; fail=$((fail+1)); return; } ;;
  esac; echo "OK $n"; ok=$((ok+1)); }
get bottom "https://github.com/ClementTsang/bottom/releases/download/0.10.2/bottom-x86_64-unknown-linux-musl.tar.gz" tgz
get nu "https://github.com/nushell/nushell/releases/download/0.101.0/nu-0.101.0-x86_64-unknown-linux-gnu.tar.gz" tgz
get taplo "https://github.com/tamasfe/taplo/releases/download/0.9.3/taplo-linux-x86_64.gz" gz
get tfsec "https://github.com/aquasecurity/tfsec/releases/download/v1.28.11/tfsec-linux-amd64" raw
get terrascan "https://github.com/tenable/terrascan/releases/download/v1.19.9/terrascan_1.19.9_Linux_x86_64.tar.gz" tgz
get kube-bench "https://github.com/aquasecurity/kube-bench/releases/download/v0.10.6/kube-bench_0.10.6_linux_amd64.tar.gz" tgz
get osv-scanner "https://github.com/google/osv-scanner/releases/download/v1.9.1/osv-scanner_linux_amd64" raw
get skaffold "https://github.com/GoogleContainerTools/skaffold/releases/download/v2.13.2/skaffold-linux-amd64" raw
get tilt "https://github.com/tilt-dev/tilt/releases/download/v0.33.21/tilt.0.33.21.linux.x86_64.tar.gz" tgz
get flux "https://github.com/fluxcd/flux2/releases/download/v2.4.0/flux_2.4.0_linux_amd64.tar.gz" tgz
get dstat "https://github.com/dstat-real/dstat/releases/download/v0.7.4/dstat" raw
echo "=== সফল=$ok ব্যর্থ=$fail ==="
