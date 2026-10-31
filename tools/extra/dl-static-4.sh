#!/bin/bash
DL=/workspace/tool-dl4; BIN=/workspace/ZyraxonOS/rootfs/usr/local/bin
mkdir -p "$DL" "$BIN"; cd "$DL"
dl(){ curl -fsSL --retry 2 --connect-timeout 25 -o "$1" "$2" && echo "dl ok $(basename $1)" || echo "dl FAIL $(basename $1)"; }
dl bottom.tar.gz "https://github.com/ClementTsang/bottom/releases/download/0.14.9/bottom_x86_64-unknown-linux-gnu.tar.gz"
dl radare2.deb "https://github.com/radareorg/radare2/releases/download/6.2.4/radare2_6.2.4_amd64.deb"
dl jadx.zip "https://github.com/skylot/jadx/releases/download/v1.5.6/jadx-1.5.6.zip"
dl dex2jar.zip "https://github.com/pxb1988/dex2jar/releases/download/v2.4/dex-tools-v2.4.zip"
dl telegraf.tar.gz "https://dl.influxdata.com/telegraf/releases/telegraf-1.32.3_linux_amd64.tar.gz"
dl dstat.py "https://raw.githubusercontent.com/dstat-real/dstat/master/dstat"
# bottom
rm -rf xb; mkdir xb; tar -xzf bottom.tar.gz -C xb && install -m755 xb/bottom "$BIN/bottom" && echo "ok bottom"
# telegraf
rm -rf xt; mkdir xt; tar -xzf telegraf.tar.gz -C xt 2>/dev/null; tb=$(find xt -type f -name telegraf | head -1); [ -n "$tb" ] && install -m755 "$tb" "$BIN/telegraf" && echo "ok telegraf"
# dstat
install -m755 dstat.py "$BIN/dstat" && echo "ok dstat"
# jadx
rm -rf /workspace/ZyraxonOS/rootfs/opt/jadx; mkdir -p /workspace/ZyraxonOS/rootfs/opt/jadx; unzip -oq jadx.zip -d /workspace/ZyraxonOS/rootfs/opt/jadx
printf '#!/bin/sh\nexec java -jar /opt/jadx/lib/jadx-cli-*.jar "$@"\n' > "$BIN/jadx"; chmod 755 "$BIN/jadx"; echo "ok jadx"
# dex2jar
rm -rf /workspace/ZyraxonOS/rootfs/opt/dex2jar; mkdir -p /workspace/ZyraxonOS/rootfs/opt/dex2jar; unzip -oq dex2jar.zip -d /workspace/ZyraxonOS/rootfs/opt/dex2jar
printf '#!/bin/sh\nexec /opt/dex2jar/d2j-dex2jar.sh "$@"\n' > "$BIN/dex2jar"; chmod 755 "$BIN/dex2jar"; echo "ok dex2jar"
# openapi-generator
mkdir -p /workspace/ZyraxonOS/rootfs/opt/openapi-generator
curl -fsSL -o /workspace/ZyraxonOS/rootfs/opt/openapi-generator/openapi-generator-cli.jar "https://github.com/OpenAPITools/openapi-generator/releases/download/v7.10.0/openapi-generator-cli-7.10.0.jar" && printf '#!/bin/sh\nexec java -jar /opt/openapi-generator/openapi-generator-cli.jar "$@"\n' > "$BIN/openapi-generator" && chmod 755 "$BIN/openapi-generator" && echo "ok openapi-generator"
# radare2 deb
cp radare2.deb /workspace/ZyraxonOS/rootfs/tmp/radare2.deb
