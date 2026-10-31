#!/usr/bin/env python3
"""Boot ZyraxonOS and log in over the serial console to debug the desktop."""
import os, socket, subprocess, sys, time
ROOT="/workspace/zyraxonos-build"
SOCK="/tmp/zx-dbg.sock"
if os.path.exists(SOCK): os.remove(SOCK)
q=subprocess.Popen(["qemu-system-x86_64","-m","2560","-smp","2","-machine","q35",
 "-kernel",f"{ROOT}/iso/live/vmlinuz","-initrd",f"{ROOT}/iso/live/initrd.img",
 "-append","boot=live components console=ttyS0,115200",
 "-cdrom",f"{ROOT}/ZyraxonOS-1.0-amd64.iso","-boot","d","-display","none","-vga","std",
 "-serial",f"unix:{SOCK},server,nowait"])
print("qemu",q.pid,flush=True)
time.sleep(3)
s=None
for _ in range(120):
    try:
        s=socket.socket(socket.AF_UNIX,socket.SOCK_STREAM); s.connect(SOCK); break
    except OSError: time.sleep(0.5)
s.settimeout(1.0)
buf=b""
def drain(t):
    global buf
    end=time.time()+t
    while time.time()<end:
        try:
            d=s.recv(65536)
            if not d: break
            buf+=d
        except socket.timeout: pass
def send(t):
    s.sendall((t+"\n").encode()); time.sleep(1.2); drain(3)
drain(150)
print("=== reached login:", b"login:" in buf)
send("zyraxon"); drain(3); send("zyraxon"); drain(5)
for c in ["systemctl is-active lightdm","systemctl status lightdm --no-pager -l | tail -20",
          "ls -la /var/log/lightdm/ 2>&1 | head","cat /var/log/lightdm/lightdm.log 2>&1 | tail -30",
          "cat /var/log/lightdm/x-0.log 2>&1 | tail -30",
          "ps aux | grep -E 'X|lightdm|xfce' | grep -v grep | head"]:
    send(c)
out=buf.decode("utf-8","replace")
print("="*70)
print(out[-6000:])
s.close(); q.kill()
