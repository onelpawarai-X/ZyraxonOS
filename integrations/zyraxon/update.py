#!/usr/bin/env python3
"""ZyraxonOS auto-update daemon.

Watches the ZyraxonOS and ZYRAXON-AI GitHub releases and, when a newer
tag appears, pushes a glass toast to every running desktop. With --once
it checks a single time (used by `zx update`); otherwise it loops.
"""
import json
import os
import subprocess
import sys
import time
import urllib.request

OS_REPO = "onelpawarai-X/ZyraxonOS"
AI_REPO = "onelpawarai-X/ZYRAXON-AI"
STATE = "/var/lib/zyraxon/update-state.json"
VERSION = "9.0.0"


def _latest_tag(repo: str):
    url = f"https://api.github.com/repos/{repo}/releases/latest"
    req = urllib.request.Request(url, headers={"User-Agent": "ZyraxonOS-updater"})
    try:
        with urllib.request.urlopen(req, timeout=15) as r:
            return json.load(r).get("tag_name", "").lstrip("v")
    except Exception:
        return ""


def _load_state() -> dict:
    try:
        with open(STATE) as fh:
            return json.load(fh)
    except Exception:
        return {}


def _save_state(state: dict) -> None:
    os.makedirs(os.path.dirname(STATE), exist_ok=True)
    with open(STATE, "w") as fh:
        json.dump(state, fh)


def _notify(title: str, body: str) -> None:
    for cmd in (["notify-send", title, body], ["dunstify", title, body]):
        try:
            subprocess.run(cmd, timeout=5, check=True)
            return
        except Exception:
            continue


def check() -> None:
    state = _load_state()
    changed = False

    for key, repo in (("os", OS_REPO), ("ai", AI_REPO)):
        tag = _latest_tag(repo)
        if tag and tag != state.get(key):
            if state.get(key):
                name = "ZyraxonOS" if key == "os" else "ZYRAXON AI"
                _notify(f"{name} update available", f"New version {tag} is ready.")
            state[key] = tag
            changed = True

    if changed:
        _save_state(state)

    # A newer OS release pulls in the small patch automatically, so the
    # system updates without a reinstall.
    if state.get("os") and state["os"] != VERSION:
        try:
            subprocess.run(["/usr/local/bin/zyraxon-ota", "auto"], timeout=1800)
        except Exception:
            pass


def main() -> int:
    once = "--once" in sys.argv
    if once:
        check()
        state = _load_state()
        print(f"ZyraxonOS {state.get('os', VERSION)} | ZYRAXON AI {state.get('ai', '?')}")
        return 0

    while True:
        check()
        time.sleep(6 * 60 * 60)


if __name__ == "__main__":
    raise SystemExit(main())
