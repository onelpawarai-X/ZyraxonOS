#!/bin/bash
# Enable the Kali Linux repository so the security toolset can be installed.
# Run as root inside the ZyraxonOS image (or at build time in a hook).
set -euo pipefail
KEYRING=/usr/share/keyrings/kali-archive-keyring.gpg
if [ ! -f "$KEYRING" ]; then
  curl -fsSL https://archive.kali.org/archive-key.asc | gpg --dearmor -o "$KEYRING"
fi
cat > /etc/apt/sources.list.d/kali.list <<SRC
deb [signed-by=$KEYRING] https://http.kali.org/kali kali-rolling main contrib non-free non-free-firmware
SRC
apt-get update
echo "Kali repository enabled."
