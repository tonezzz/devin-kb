# Devin Desktop sluggishness (learned 2026-09-27, tony-omen)

Companion to `devin-desktop-crash-runbook.md`. Signatures of "Devin feels sluggish"
vs an actual crash.

## Findings from the 2026-09-27 investigation

- **Giant session = permanently hot renderer.** Session `flannel-glitter`
  (1100+ message nodes, `sessions.db` 2.5 GB) kept its window renderer at
  70–150% interval CPU even while the agent was idle waiting for input.
  Watchdog flags it every run but `WATCHDOG_RENDERER_KILL=0` (correct —
  it's busy, not wedged). Remedy: close the session; renderer calms
  immediately. Keep `sessions.db` small — archive/close old sessions.
- **Leaked tool-spawned scope.** `app-devin-desktop-3034335.scope` survived
  its session (vcast input-bridge test server, port 13100) for 2 days,
  accumulating 13h40 CPU and peaking at 10.5 GB mem / 7.6 GB swap.
  The watchdog only cleans orphaned scopes when the *main* process is dead —
  scopes that outlive their session while the app stays up are never cleaned.
  Check: `systemctl --user list-units --type=scope --state=active 'app-devin-desktop-*'`
  — expect exactly ONE per running app instance.
- **zram exhaustion amplifies everything.** zram0 was 11.5/12 GB (96%),
  15 GB swapped total; Devin allocations stall on page-ins.
  Raised `zram-swap-setup.sh` to `--size 24G` (pending reboot —
  never `swapoff` a nearly-full zram live; it has to page everything
  back into RAM and can OOM-stall the box).
- **NVML mismatch** (`NVML library version 595.91` vs running module):
  driver update installed without reboot — GPU work silently falls back
  to CPU until rebooted.

## Offload to mn01 (same day)

Two always-on services moved omen → mn01 (i5-7400T, mostly idle):

- `yolo-xiaomi` (:8780) — ~24% CPU busy-loop; pulls frames from go2rtc on
  tony-dell and POSTs to tony-ha, so nothing needed omen locally. HA config
  now points at `mn01.taila0626a.ts.net:8780` (tailnet = survives mn01
  leaving LAN). Deps: `~/.cache/ultralytics-yolo-venv` on mn01 (torch-cpu
  wheels install fine on py3.14). Old unit disabled on omen.
- `weaviate-embedding` (:5000, all-MiniLM-L6-v2, ~500MB RSS) — all callers
  use `localhost:5000`, so omen keeps `weaviate-embed-proxy.socket`
  (systemd-socket-proxyd → 100.106.196.22:5000). Nightly weaviate-index
  unchanged.

Other wins: netdata container on omen was at ~26% CPU on default 1s
interval → `update every = 5` in-container (now ~1.5%). Its restart exposed
a stale NVIDIA CDI spec (`/etc/cdi`, `/var/run/cdi` referenced removed
595.84 libs after the 595.91 update) — patched both in place with sed;
nvidia-cdi regen is still blocked by the NVML kernel-module mismatch until
the pending reboot.

## 2026-10-21: watchdog relaunching onto the greeter display

Symptom: "Devin very lagging" but `pgrep -c devin-desktop` = 0 — the app
wasn't running at all. Watchdog log showed `Auto-restarting devin-desktop
on DISPLAY=:1024` every ~30 min for 36h+: the auto-restart iterated
`/tmp/.X11-unix/X*` in glob order, and gdm's rootless Xwayland socket
(`X1024`, owned by `gdm-greeter`) sorts before the user's CRD Xvfb
(`X20`). Every launch landed on the greeter display, died on auth,
retried forever — silent because the old code never checked survival.

Diagnosis: `stat -c %U /tmp/.X11-unix/X*` — the socket file's owner is the
X server's UID; the socket owned by `tony` is the real session. Also
`systemctl --user list-units | grep auto-restart` found
`yolo-xiaomi.service` crash-looping (5,766 restarts, each a pip-install
burst) even though the service had moved to mn01 — `disabled` units still
run if never `stop`ped.

Fix (commit chaba `66e50037f`, deployed to omen+dell `~/.local/bin/`):
`display_targets()` orders displays by socket ownership (ours first, with
the server's own `-auth` file) and auto-restart now logs an ALERT if the
launch doesn't survive 10s. `WATCHDOG_DISPLAY`/`WATCHDOG_XAUTHORITY` conf
overrides exist if ever needed.

## Quick triage commands

```bash
tail -60 ~/.local/share/devin/cli/watchdog.log          # hot renderer / hang dialog / restart-loop flags
pgrep -c devin-desktop                                 # 0 = app not running at all
systemctl --user list-units --type=scope --state=active 'app-devin-desktop-*'
systemctl --user list-units | grep -i auto-restart     # crash-looping units = lag amplifier
stat -c '%U %n' /tmp/.X11-unix/X*                      # user-owned socket = the real display
ps -eo pid,%cpu,%mem,etimes,args --sort=-%cpu | head -25
swapon --show; zramctl
sqlite3 ~/.local/share/devin/cli/sessions.db \
  "SELECT id,title FROM sessions ORDER BY last_activity_at DESC LIMIT 10;"
pgrep -af 'devin acp'   # active agent sessions
```
