#!/usr/bin/env python3
import os, socket, subprocess, time
ROOT="/workspace/zyraxonos-build"; SOCK="/tmp/zx-dbg2.sock"
if os.path.exists(SOCK): os.remove(SOCK)
q=subprocess.Popen(["qemu-system-x86_64","-m","2560","-smp","2","-machine","q35",
 "-kernel",f"{ROOT}/iso/live/vmlinuz","-initrd",f"{ROOT}/iso/live/initrd.img",
 "-append","boot=live components console=ttyS0,115200",
 "-cdrom",f"{ROOT}/ZyraxonOS-1.0-amd64.iso","-boot","d","-display","none","-vga","std",
 "-serial",f"unix:{SOCK},server,nowait"])
time.sleep(3)
s=None
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
drain(150)
send("zyraxon"); drain(3); send("zyraxon"); drain(6)
for c in ["echo zyraxon | sudo -S true 2>/dev/null; ps aux | grep -E 'xfce4-session|xfwm4|xfce4-panel|xfdesktop' | grep -v grep",
          "sudo cat /var/log/lightdm/lightdm.log 2>&1 | tail -25",
          "sudo grep -iE 'autologin|session' /var/log/lightdm/lightdm.log 2>&1 | tail -15",
          "ls /usr/share/xsessions/; cat /usr/share/xsessions/xfce.desktop 2>&1"]:
    send(c)
print("="*70); open("/workspace/dbg2-full.txt","wb").write(buf)
s.close(); q.kill()
