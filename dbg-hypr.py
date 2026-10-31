#!/usr/bin/env python3
"""Boot ZyraxonOS in QEMU with an interactive serial console and run
diagnostic commands inside the guest, then print the output.

Usage: python3 dbg-hypr.py "cmd1" "cmd2" ...
"""
import os, socket, subprocess, sys, time

ROOT = "/workspace/zyraxonos-build"
K = os.path.join(ROOT, "iso", "live", "vmlinuz")
I = os.path.join(ROOT, "iso", "live", "initrd.img")
ISO = os.path.join(ROOT, "ZyraxonOS-9.0.0-amd64.iso")
SOCK = "/tmp/zyr-serial.sock"

CMDS = sys.argv[1:] or [
    "cat /etc/systemd/system/zyraxon-desktop.service",
    "systemctl status zyraxon-desktop --no-pager -l 2>&1 | tail -25",
    "cat /tmp/zyraxon-session.log 2>&1 | tail -40",
    "ls -la /run/user/1000 2>&1",
    "cat /etc/os-release | head -2",
]


def main():
    if os.path.exists(SOCK):
        os.remove(SOCK)
    qemu = subprocess.Popen([
        "qemu-system-x86_64", "-m", "3072", "-smp", "2", "-machine", "q35",
        "-kernel", K, "-initrd", I,
        "-append", "boot=live components console=ttyS0,115200",
        "-cdrom", ISO, "-boot", "d", "-display", "none", "-vga", "virtio",
        "-serial", f"unix:{SOCK},server,nowait",
    ])
    print("qemu pid", qemu.pid, flush=True)
    time.sleep(3)
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
                if not d:
                    break
                buf.extend(d)
            except socket.timeout:
                pass

    print("booting, waiting for login ...", flush=True)
    drain(150)
    txt = buf.decode("utf-8", "replace")
    print("--- reached login:", "login:" in txt, flush=True)

    for c in CMDS:
        s.sendall(f"\n{c}\n".encode())
        drain(7)
    drain(4)
    out = buf.decode("utf-8", "replace")
    print("=" * 72)
    print(out[-9000:])

    s.close()
    qemu.kill()
    try:
        qemu.wait(timeout=5)
    except Exception:
        pass


if __name__ == "__main__":
    main()
