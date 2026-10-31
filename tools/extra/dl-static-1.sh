#!/bin/bash
DL=/workspace/tool-dl; BIN=/workspace/ZyraxonOS/rootfs/usr/local/bin
mkdir -p "$DL" "$BIN"; cd "$DL"
ok=0; fail=0
get(){
  n="$1"; u="$2"; k="$3"
  f="$DL/$(basename "$u")"
  if ! curl -fsSL --retry 2 --connect-timeout 20 -o "$f" "$u"; then echo "FAIL-DL $n"; fail=$((fail+1)); return; fi
  case "$k" in
    raw) install -m755 "$f" "$BIN/$n" ;;
    gz)  gunzip -c "$f" > "$BIN/$n" && chmod 755 "$BIN/$n" ;;
    tgz) rm -rf "$DL/x_$n"; mkdir -p "$DL/x_$n"; tar -xzf "$f" -C "$DL/x_$n" 2>/dev/null
         b=$(find "$DL/x_$n" -type f -name "$n" | head -1); [ -z "$b" ] && b=$(find "$DL/x_$n" -maxdepth 2 -type f -perm -u+x ! -name "*.txt" ! -name "LICENSE*" | head -1)
         [ -n "$b" ] && install -m755 "$b" "$BIN/$n" || { echo "FAIL-EXTRACT $n"; fail=$((fail+1)); return; } ;;
    zip) rm -rf "$DL/x_$n"; mkdir -p "$DL/x_$n"; unzip -oq "$f" -d "$DL/x_$n"
         b=$(find "$DL/x_$n" -type f -name "$n" | head -1); [ -z "$b" ] && b=$(find "$DL/x_$n" -type f -perm -u+x | head -1)
         [ -n "$b" ] && install -m755 "$b" "$BIN/$n" || { echo "FAIL-EXTRACT $n"; fail=$((fail+1)); return; } ;;
  esac
  echo "OK $n"; ok=$((ok+1))
}
get helm "https://get.helm.sh/helm-v3.16.3-linux-amd64.tar.gz" tgz
get terraform "https://releases.hashicorp.com/terraform/1.9.8/terraform_1.9.8_linux_amd64.zip" zip
get packer "https://releases.hashicorp.com/packer/1.11.2/packer_1.11.2_linux_amd64.zip" zip
get vault "https://releases.hashicorp.com/vault/1.17.6/vault_1.17.6_linux_amd64.zip" zip
get consul "https://releases.hashicorp.com/consul/1.20.1/consul_1.20.1_linux_amd64.zip" zip
get nomad "https://releases.hashicorp.com/nomad/1.9.3/nomad_1.9.3_linux_amd64.zip" zip
get deno "https://github.com/denoland/deno/releases/download/v2.1.4/deno-x86_64-unknown-linux-gnu.zip" zip
get k9s "https://github.com/derailed/k9s/releases/download/v0.32.7/k9s_Linux_amd64.tar.gz" tgz
get lazydocker "https://github.com/jesseduffield/lazydocker/releases/download/v0.23.1/lazydocker_0.23.1_Linux_x86_64.tar.gz" tgz
get ctop "https://github.com/bcicen/ctop/releases/download/v0.7.7/ctop-0.7.7-linux-amd64" raw
get stern "https://github.com/stern/stern/releases/download/v1.30.0/stern_1.30.0_linux_amd64.tar.gz" tgz
get k6 "https://github.com/grafana/k6/releases/download/v0.55.0/k6-v0.55.0-linux-amd64.tar.gz" tgz
get hadolint "https://github.com/hadolint/hadolint/releases/download/v2.12.0/hadolint-Linux-x86_64" raw
get trivy "https://github.com/aquasecurity/trivy/releases/download/v0.57.1/trivy_0.57.1_Linux-64bit.tar.gz" tgz
get grype "https://github.com/anchore/grype/releases/download/v0.86.1/grype_0.86.1_linux_amd64.tar.gz" tgz
get syft "https://github.com/anchore/syft/releases/download/v1.18.1/syft_1.18.1_linux_amd64.tar.gz" tgz
get minikube "https://github.com/kubernetes/minikube/releases/download/v1.34.0/minikube-linux-amd64" raw
get zellij "https://github.com/zellij-org/zellij/releases/download/v0.41.2/zellij-x86_64-unknown-linux-musl.tar.gz" tgz
get bandwhich "https://github.com/imsnif/bandwhich/releases/download/v0.22.0/bandwhich-v0.22.0-x86_64-unknown-linux-musl.tar.gz" tgz
get vegeta "https://github.com/tsenart/vegeta/releases/download/v12.12.0/vegeta_12.12.0_linux_amd64.tar.gz" tgz
get grpcurl "https://github.com/fullstorydev/grpcurl/releases/download/v1.9.2/grpcurl_1.9.2_linux_x86_64.tar.gz" tgz
get buf "https://github.com/bufbuild/buf/releases/download/v1.47.2/buf-Linux-x86_64" raw
get kube-linter "https://github.com/stackrox/kube-linter/releases/download/v0.7.1/kube-linter-linux.tar.gz" tgz
get kubeval "https://github.com/instrumenta/kubeval/releases/download/v0.16.1/kubeval-linux-amd64.tar.gz" tgz
get conftest "https://github.com/open-policy-agent/conftest/releases/download/v0.58.0/conftest_0.58.0_Linux_x86_64.tar.gz" tgz
get opa "https://github.com/open-policy-agent/opa/releases/download/v1.0.0/opa_linux_amd64_static" raw
get amass "https://github.com/owasp-amass/amass/releases/download/v4.2.0/amass_Linux_amd64.zip" zip
get feroxbuster "https://github.com/epi052/feroxbuster/releases/download/v2.11.0/x86_64-linux-feroxbuster.zip" zip
get chezmoi "https://github.com/twpayne/chezmoi/releases/download/v2.53.1/chezmoi_2.53.1_linux_amd64.tar.gz" tgz
get websocat "https://github.com/vi/websocat/releases/download/v1.13.0/websocat.x86_64-unknown-linux-musl" raw
echo "=== সফল=$ok ব্যর্থ=$fail ==="
