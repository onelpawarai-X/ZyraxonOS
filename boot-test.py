#!/usr/bin/env python3
"""Boot the real ZyraxonOS ISO headless and capture screenshots."""
import json, os, socket, subprocess, time
ROOT="/workspace/zyraxonos-build"
ISO=os.path.join(ROOT,"ZyraxonOS-1.0-amd64.iso")
K=os.path.join(ROOT,"iso","live","vmlinuz")
I=os.path.join(ROOT,"iso","live","initrd.img")
OUT="/workspace/zyraxonos-build/boot-shots"; os.makedirs(OUT,exist_ok=True)
SOCK="/tmp/zx-boot.sock"
if os.path.exists(SOCK): os.remove(SOCK)
q=subprocess.Popen(["qemu-system-x86_64","-m","2560","-smp","2","-machine","q35",
 "-kernel",K,"-initrd",I,
 "-append","boot=live components console=ttyS0,115200 quiet",
 "-cdrom",ISO,"-boot","d","-display","none","-vga","std",
 "-qmp","unix:/tmp/zx-boot.sock,server,nowait","-serial",f"file:{OUT}/serial.log"])
print("qemu pid",q.pid,flush=True)
def conn():
    end=time.time()+90
    while time.time()<end:
        try:
            s=socket.socket(socket.AF_UNIX,socket.SOCK_STREAM); s.connect(SOCK); return s
        except OSError: time.sleep(0.3)
    raise SystemExit("qmp failed")
s=conn(); f=s.makefile("rwb"); f.readline()
def cmd(n,**a):
    f.write((json.dumps({"execute":n,"arguments":a})+"\n").encode()); f.flush()
    while True:
        l=f.readline()
        if not l: return None
        m=json.loads(l)
        if "return" in m or "error" in m: return m
cmd("qmp_capabilities")
for m in [60,100,150,200,260,320]:
    time.sleep(20)
    if m==60:
        cmd("send-key",keys=[{"type":"qcode","data":"ret"}])
    p=os.path.join(OUT,f"t{m:03d}.png")
    cmd("screendump",filename=p,format="png")
    print("shot",os.path.basename(p),flush=True)
cmd("quit")
try: q.wait(timeout=10)
except Exception: q.kill()
log=open(f"{OUT}/serial.log",errors="replace").read()
print("PANIC:",log.count("Kernel panic"))
print("lightdm:", "lightdm" in log.lower())
print("xfce:", "xfce" in log.lower())
print("graphical:", "graphical.target" in log)
print("DONE")
