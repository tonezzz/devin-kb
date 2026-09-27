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

## Quick triage commands

```bash
tail -60 ~/.local/share/devin/cli/watchdog.log          # hot renderer / hang dialog flags
systemctl --user list-units --type=scope --state=active 'app-devin-desktop-*'
ps -eo pid,%cpu,%mem,etimes,args --sort=-%cpu | head -25
swapon --show; zramctl
sqlite3 ~/.local/share/devin/cli/sessions.db \
  "SELECT id,title FROM sessions ORDER BY last_activity_at DESC LIMIT 10;"
pgrep -af 'devin acp'   # active agent sessions
```
