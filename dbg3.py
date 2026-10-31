#!/usr/bin/env python3
import os, socket, subprocess, time
ROOT="/workspace/zyraxonos-build"; SOCK="/tmp/zx-dbg3.sock"
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
drain(140)
send("zyraxon"); drain(3); send("zyraxon"); drain(6)
for c in ["sudo sed -n '/^\\[Seat/,/^\\[XDMC/p' /etc/lightdm/lightdm.conf | grep -v '^#'",
          "sudo cat /var/log/lightdm/lightdm.log | grep -iE 'autologin|Activating|session' | tail -20",
          "sudo ls -la /home/zyraxon 2>&1 | head -3; id zyraxon",
          "sudo cat /etc/lightdm/lightdm.conf.d/*.conf 2>&1 | grep -iE 'autologin|session'"]:
    send(c)
open("/workspace/dbg3-full.txt","wb").write(buf)
s.close(); q.kill()
