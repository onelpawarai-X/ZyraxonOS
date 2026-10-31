#!/usr/bin/env python3
"""Boot ZyraxonOS in QEMU, let the glass desktop start, then grab a real
screenshot from INSIDE the guest with grim and copy it out over a 9p share.

This proves the desktop actually renders, independently of QEMU's own
screendump (which can miss the flipped DRM buffer).
"""
import os, socket, subprocess, sys, time

ROOT = "/workspace/zyraxonos-build"
K = os.path.join(ROOT, "iso", "live", "vmlinuz")
I = os.path.join(ROOT, "iso", "live", "initrd.img")
ISO = os.path.join(ROOT, "ZyraxonOS-9.0.0-amd64.iso")
SHARE = "/tmp/zyrshare"
SOCK = "/tmp/zyr-grab.sock"
WAIT = int(sys.argv[1]) if len(sys.argv) > 1 else 200

os.makedirs(SHARE, exist_ok=True)
for f in os.listdir(SHARE):
    if f != "diag.sh":
        os.remove(os.path.join(SHARE, f))
if os.path.exists(SOCK):
    os.remove(SOCK)

qemu = subprocess.Popen([
    "qemu-system-x86_64", "-m", "3072", "-smp", "2", "-machine", "q35",
    "-kernel", K, "-initrd", I,
    "-append", "boot=live components console=ttyS0,115200",
    "-cdrom", ISO, "-boot", "d", "-display", "none", "-vga", "std",
    "-virtfs", f"local,path={SHARE},mount_tag=host0,security_model=none",
    "-serial", f"unix:{SOCK},server,nowait",
])
print("qemu pid", qemu.pid, flush=True)

s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
for _ in range(120):
    try:
        s.connect(SOCK); break
    except OSError:
        time.sleep(0.5)
s.settimeout(1.0)
buf = bytearray()

def drain(seconds):
    end = time.time() + seconds
    while time.time() < end:
        try:
            d = s.recv(65536)
            if d:
                buf.extend(d)
        except socket.timeout:
            pass

print("booting, waiting for login ...", flush=True)
drain(WAIT)
print("--- login reached:", b"login:" in buf, flush=True)

cmds = [
    "mkdir -p /mnt/host",
    "mount -t 9p -o trans=virtio,version=9p2000.L host0 /mnt/host",
    "chmod +x /mnt/host/diag.sh 2>/dev/null; bash /mnt/host/diag.sh",
    "ls -la /mnt/host/",
]
for c in cmds:
    s.sendall(f"\n{c}\n".encode())
    drain(45 if "diag.sh" in c else 8)
drain(5)

print("=" * 60)
print(buf.decode("utf-8", "replace")[-3500:])
print("=" * 60)

s.close()
qemu.kill()
try:
    qemu.wait(timeout=5)
except Exception:
    pass

for f in sorted(os.listdir(SHARE)):
    print("HOST GOT:", f, os.path.getsize(os.path.join(SHARE, f)), "bytes")
