#!/usr/bin/env python3
import os, socket, subprocess, time
ROOT="/workspace/zyraxonos-build"; SOCK="/tmp/zx-dbg4.sock"
if os.path.exists(SOCK): os.remove(SOCK)
q=subprocess.Popen(["qemu-system-x86_64","-m","2560","-smp","2","-machine","q35",
 "-kernel",f"{ROOT}/iso/live/vmlinuz","-initrd",f"{ROOT}/iso/live/initrd.img",
 "-append","boot=live components console=ttyS0,115200",
 "-cdrom",f"{ROOT}/ZyraxonOS-1.0-amd64.iso","-boot","d","-display","none","-vga","std",
 "-serial",f"unix:{SOCK},server,nowait"])
time.sleep(3); s=None
for _ in range(120):
    try: s=socket.socket(socket.AF_UNIX,socket.SOCK_STREAM); s.connect(SOCK); break
    except OSError: time.sleep(0.5)
s.settimeout(1.0); buf=b""
def drain(t):
    global buf
    end=time.time()+t
    while time.time()<end:
        try:
            d=s.recv(65536)
            if not d: break
            buf+=d
        except socket.timeout: pass
def send(t): s.sendall((t+"\n").encode()); time.sleep(1.5); drain(4)
drain(170)
send("zyraxon"); drain(3); send("zyraxon"); drain(6)
for c in ["systemctl is-active zyraxon-desktop",
          "systemctl status zyraxon-desktop --no-pager -l 2>&1 | tail -18",
          "journalctl -b -u zyraxon-desktop --no-pager 2>&1 | tail -30",
          "ps aux | grep -E 'Xorg|startxfce|xfwm4|xfce4-panel|xfdesktop' | grep -v grep | head"]:
    send(c)
open("/workspace/dbg4-full.txt","wb").write(buf)
s.close(); q.kill()
