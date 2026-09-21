# Devin Desktop crash recovery (learned 2026-09-21, tony-omen)

Canonical sources: `chaba` repo `scripts/devin/` + `docs/ssot/infrastructure/ssot.devin.maintenance.yml` + chaba `AGENTS.md` runbook section.

## Crash signatures → fixes

| Signature | Cause | Fix |
|---|---|---|
| `renderer process gone (reason: crashed, code: 5)` + kernel log `apparmor="DENIED" ... capability=sys_admin comm="devin-desktop"` | Ubuntu ≥24.04 `kernel.apparmor_restrict_unprivileged_userns=1` blocks the Electron sandbox; devin-desktop ships no profile | Install `scripts/devin/apparmor-devin-desktop` → `/etc/apparmor.d/devin-desktop`, `sudo apparmor_parser -r` (or `scripts/devin/install-devin-host.sh`) |
| `renderer process gone (reason: launch-failed, code: 1002)` on every relaunch after a dirty shutdown | Corrupted `~/.config/Devin/{GPUCache, Code Cache, CachedData}` | Rename those dirs, relaunch |
| App dead but `app-devin-desktop-*.scope` still active | Orphaned tool-spawned children (headless Chrome `user-data-dir=/tmp/chrome-devtools-profile`, stuck probes) keep burning CPU | `systemctl --user stop app-devin-desktop-*.scope`; the watchdog now handles this automatically |
| Dialog "The window terminated unexpectedly (reason: 'killed')" + watchdog.log shows `Killing wedged renderer` | Watchdog killed a legit busy renderer (e.g. active agent session, indexing) — looks like a crash but isn't | The renderer is dead; safest recovery is a full `nohup` relaunch. See watchdog policy below — it now requires ~10 min of sustained CPU before killing |
| Dialog "The window terminated unexpectedly" won't dismiss via xdotool | Electron crash dialog ignores XTEST synthetic input | Do NOT `wmctrl -c` the dialog — it tears down the whole app (observed 2026-09-21). Kill the main process and relaunch instead |

## Headless relaunch

```bash
ssh <host> 'export DISPLAY=:0.0 XAUTHORITY=/run/user/1000/gdm/Xauthority \
  DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus; \
  nohup /usr/bin/devin-desktop > ~/.local/share/devin/cli/devin-restart-$(date +%Y%m%d-%H%M%S).log 2>&1 </dev/null &'
```

- Display differs per host: tony-omen `:0.0`, tony-dell `:1` — check `ls /tmp/.X11-unix/X*`.
- Prefer `nohup` — `systemd-run --user` launches were observed dying ~1.3s in on tony-omen.
- Verify: `pgrep -c devin-desktop`, renderer count, `wmctrl -l | grep -i devin`.

## Watchdog (deployed on tony-dell + tony-omen via cron every 10 min)

`~/.local/bin/devin-desktop-watchdog.sh` (source: `scripts/devin/devin-desktop-watchdog.sh`):

- kills renderers only when wedged: >50% CPU sustained across two consecutive runs (~10 min) plus a 10s in-run hold, with a 2-min startup grace — legit busy work (agent sessions, indexing, SANE/scan jobs) is left alone. Hot PIDs tracked in `~/.local/state/devin-watchdog/hot-renderers`. NOTE: the old "hot for 10s" policy killed a renderer mid-scan-session on tony-omen 2026-09-21 and presented as a crash.
- stops orphaned `app-devin-desktop-*` scopes when the main process is gone
- logs + desktop-notifies new AppArmor denials and renderer crashes (journal scan, last-15-min window)
- optional auto-restart: `touch ~/.config/devin/watchdog-autorestart` (30-min cooldown)
- log: `~/.local/share/devin/cli/watchdog.log`

Gotcha found during deployment: detect the main process by `$BIN` prefix while excluding `--type=*`, `cli.js`, and crashpad children — an anchored `^...$` match misses GUI mains launched with flags (e.g. `--no-sandbox`) and would kill a live instance. `~/.config/Devin/code.lock` holds the GUI main PID as a fallback check.

## Related fix: michael-dev on tony-omen

The podman quadlet `~/.config/containers/systemd/michael-dev.container` on tony-omen had `HealthCmd` curling port 8124 (copied from the tony-dell deployment, where HA binds 8124 to dodge tony-ha on 8123). On tony-omen HA binds 8123, so healthchecks failed every 30s (streak >1000, journal churn, unhealthy status). Fixed 2026-09-21 by pointing HealthCmd at 8123. The omen quadlet is not tracked in the repo — only `stacks/tony-dell/michael-dev/michael-dev.container` is.
