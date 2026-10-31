#!/bin/bash
DL=/workspace/tool-dl; BIN=/workspace/ZyraxonOS/rootfs/usr/local/bin
mkdir -p "$DL" "$BIN"; cd "$DL"; ok=0; fail=0
get(){ n="$1"; u="$2"; k="$3"; f="$DL/$(basename "$u")"
  if ! curl -fsSL --retry 2 --connect-timeout 20 -o "$f" "$u"; then echo "FAIL-DL $n"; fail=$((fail+1)); return; fi
  case "$k" in
    raw) install -m755 "$f" "$BIN/$n" ;;
    tgz) rm -rf "$DL/x_$n"; mkdir -p "$DL/x_$n"; tar -xzf "$f" -C "$DL/x_$n"
         b=$(find "$DL/x_$n" -type f -name "$n" | head -1); [ -z "$b" ] && b=$(find "$DL/x_$n" -maxdepth 2 -type f -perm -u+x ! -name "*.txt" ! -name "LICENSE*" | head -1)
         [ -n "$b" ] && install -m755 "$b" "$BIN/$n" || { echo "FAIL-EXTRACT $n"; fail=$((fail+1)); return; } ;;
    zip) rm -rf "$DL/x_$n"; mkdir -p "$DL/x_$n"; unzip -oq "$f" -d "$DL/x_$n"
         b=$(find "$DL/x_$n" -type f -name "$n" | head -1); [ -z "$b" ] && b=$(find "$DL/x_$n" -type f -perm -u+x | head -1)
         [ -n "$b" ] && install -m755 "$b" "$BIN/$n" || { echo "FAIL-EXTRACT $n"; fail=$((fail+1)); return; } ;;
  esac; echo "OK $n"; ok=$((ok+1)); }
get terraform "https://releases.hashicorp.com/terraform/1.9.8/terraform_1.9.8_linux_amd64.zip" zip
get packer "https://releases.hashicorp.com/packer/1.11.2/packer_1.11.2_linux_amd64.zip" zip
get vault "https://releases.hashicorp.com/vault/1.17.6/vault_1.17.6_linux_amd64.zip" zip
get consul "https://releases.hashicorp.com/consul/1.20.1/consul_1.20.1_linux_amd64.zip" zip
get nomad "https://releases.hashicorp.com/nomad/1.9.3/nomad_1.9.3_linux_amd64.zip" zip
get deno "https://github.com/denoland/deno/releases/download/v2.1.4/deno-x86_64-unknown-linux-gnu.zip" zip
get amass "https://github.com/owasp-amass/amass/releases/download/v4.2.0/amass_Linux_amd64.zip" zip
get feroxbuster "https://github.com/epi052/feroxbuster/releases/download/v2.11.0/x86_64-linux-feroxbuster.zip" zip
get trivy "https://github.com/aquasecurity/trivy/releases/download/v0.55.0/trivy_0.55.0_Linux-64bit.tar.gz" tgz
echo "=== সফল=$ok ব্যর্থ=$fail ==="
