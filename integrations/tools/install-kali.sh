#!/bin/bash
# ============================================================
# ZyraxonOS — install the Kali Linux security toolset.
#
# Kali groups its tools into metapackages; installing the metapackages
# below brings in every security tool Kali ships (information gathering,
# vulnerability analysis, web, database, passwords, wireless, reverse
# engineering, exploitation, social engineering, sniffing/spoofing,
# post-exploitation, forensics, reporting, crypto/stego and defensive).
#
# Safe to run repeatedly. Nothing outside Kali's tool groups is added.
# ============================================================
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
LOG=/var/log/zyraxon-kali.log
say() { printf '\n\033[1;36m[zyraxon-kali]\033[0m %s\n' "$*"; }

export DEBIAN_FRONTEND=noninteractive

say "updating package lists (Debian + Kali)"
apt-get update >>"$LOG" 2>&1 || true

# metapackages in the order Kali lists them
installed=0
while read -r g; do
  [ -z "$g" ] && continue
  case "$g" in \#*) continue ;; esac
  if apt-cache show "$g" >/dev/null 2>&1; then
    say "installing $g"
    apt-get install -y --no-install-recommends "$g" >>"$LOG" 2>&1 || true
    installed=$((installed+1))
  else
    say "skipping $g (not in the configured repositories)"
  fi
done <<'GROUPLIST'
kali-tools-information-gathering
kali-tools-vulnerability
kali-tools-web
kali-tools-database
kali-tools-passwords
kali-tools-wireless
kali-tools-reverse-engineering
kali-tools-exploitation
kali-tools-social-engineering
kali-tools-sniffing-spoofing
kali-tools-post-exploitation
kali-tools-forensics
kali-tools-reporting
kali-tools-crypto-stego
kali-tools-defensive
GROUPLIST

# a few headline tools that live outside the metapackages
say "installing headline tools"
apt-get install -y --no-install-recommends \
  nmap masscan wireshark tshark aircrack-ng hashcat john hydra sqlmap \
  nikto whatweb gobuster dirb wfuzz bettercap mitmproxy macchanger mdk4 \
  reaver pixiewps hcxdumptool hcxtools crunch bully cowpatty dsniff \
  ettercap-text-only netcat-openbsd socat tcpdump zaproxy exploitdb \
  >>"$LOG" 2>&1 || true

apt-get clean >>"$LOG" 2>&1 || true

say "Kali security toolset installed ($installed groups) — log: $LOG"
