#!/usr/bin/env python3
"""or-key-watch — warn before deployed OpenRouter keys expire or run dry.

Scans ~/.config/secrets/*.{env,txt} for sk-or-* keys (deduped), queries
GET /api/v1/key for each, and exits 1 when any key expires within
WARN_DAYS or has limit_remaining below WARN_REMAINING_USD.
Run weekly via or-key-watch.timer — a nonzero exit is picked up by
timer-sentinel which files a timer-alert card automatically.
"""
import json, os, re, sys, urllib.request
from datetime import datetime, timezone
from pathlib import Path

SECRETS = Path.home() / ".config/secrets"
WARN_DAYS = float(os.environ.get("OR_WARN_DAYS", "14"))
WARN_USD = float(os.environ.get("OR_WARN_REMAINING_USD", "0.10"))
KEY_RE = re.compile(r"sk-or-[A-Za-z0-9_-]+")


def keys():
    found = {}
    for p in sorted(SECRETS.iterdir()):
        if p.suffix not in (".env", ".txt") or not p.is_file():
            continue
        try:
            for line in p.read_text().splitlines():
                if line.lstrip().startswith("#"):
                    continue
                for m in KEY_RE.finditer(line):
                    found.setdefault(m.group(0), []).append(p.name)
        except Exception:
            pass
    return found


def check(k):
    try:
        req = urllib.request.Request(
            "https://openrouter.ai/api/v1/key",
            headers={"Authorization": f"Bearer {k}"})
        d = json.load(urllib.request.urlopen(req, timeout=15))["data"]
    except Exception as e:
        return f"key {k[:12]}... unreachable/invalid: {e}"
    exp = d.get("expires_at")
    if exp:
        left = (datetime.fromisoformat(exp.replace("Z", "+00:00"))
                - datetime.now(timezone.utc)).days
        if left < WARN_DAYS:
            return f"key {k[:12]}... expires in {left}d ({exp[:10]})"
    rem = d.get("limit_remaining")
    if rem is not None and rem < WARN_USD:
        return f"key {k[:12]}... limit_remaining ${rem}"
    return None


found = keys()
bad = []
for k, files in found.items():
    w = check(k)
    tag = ",".join(files)
    if w:
        print(f"WARN {w} (in: {tag})")
        bad.append(w)
    else:
        print(f"OK   {k[:12]}... (in: {tag})")
if not found:
    print("no sk-or- keys found in secrets dir")
sys.exit(1 if bad else 0)
