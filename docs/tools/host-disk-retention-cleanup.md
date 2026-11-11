---
title: Host disk retention & cleanup procedure
description: Standard retention policy and safe cleanup procedure for dev hosts (dispatch worktrees, backups, journald, podman, caches)
tags: [ops, disk, retention, cleanup, worktrees, backups, systemd]
category: operations
status: active
---

# Host Disk Retention & Cleanup Procedure

Standard for keeping dev-host disks from filling. Established 2026-11-11 after
idc03 hit 100% and idc02 accumulated 109G of stale dispatch worktrees.

## Retention policy

| Artifact | Location | Retain | Method |
|---|---|---|---|
| dispatch/Devin worktrees | `~/CascadeProjects/dispatch-wt-*` | 7 days | `scripts/clean-dispatch-worktrees.sh` (weekly timer) |
| worktree salvage | `~/wt-salvage/` | 30 days | pruned by same script |
| mddb DB backups | `~/mddb-backups/` | 3 days | `find -mtime +2 -delete` inside `mddb-backup.sh` (idc03) |
| Home Assistant backups (HAOS) | `/backup/` | newest 2 | `rm` + `ha backups reload` (manual, michael-ha) |
| journald | `/var/log/journal/` | 500 MB | `journalctl --rotate` then `--vacuum-size=500M` |
| podman images | `~/.local/share/containers/` | unused only | `podman image prune -f`; `-a -f` for all unused (re-pullable) |
| rebuildable caches | `~/.cache/{pip,uv,go-build,nest-worker,...}` | none | `rm -rf` when stale |
| `/tmp` scratch dirs | `/tmp/*` | if unused | check `lsof +D` for open files first |

## Safety rules

1. **Measure first** — `df -h`, then `du -x -h --max-depth=1` top-down. Know
   what you're deleting before deleting it.
2. **Never `rm -rf` git worktrees** — use `git worktree remove`. Git refuses
   dirty or locked worktrees; that refusal IS the safety check.
3. **Skip active work** — a worktree/dir with any file modified within the
   retention window is treated as live. `lsof +D <dir>` for open files.
4. **Salvage before force-removal** — dirty worktrees are tarred
   (`tgz` + `.status` + `.head`) to `~/wt-salvage/` before
   `worktree remove --force`.
5. **Retention inside backup scripts runs only after a fresh backup lands** —
   so a stalled job can never empty the directory.
6. **journald needs `--rotate` first** — `--vacuum-size` only removes
   *archived* journals; without rotate it frees 0 B.
7. **Backups: confirm before deleting** and always keep the newest N.
8. **Verify after cleanup** — `podman ps`, `systemctl --user --failed`,
   `systemctl --user is-system-running`. Stale healthcheck state
   (`Status: starting` forever) clears with `podman healthcheck run <ctr>`.

## Automation

Weekly worktree cleanup via systemd user timer on hosts that run dispatch
sessions (idc02, idc03, tony-dell):

```
~/bin/clean-dispatch-worktrees.sh            # from devin-kb scripts/
~/.config/systemd/user/dispatch-wt-clean.service
~/.config/systemd/user/dispatch-wt-clean.timer   # Sun 04:30, Persistent
```

Enable with: `systemctl --user daemon-reload && systemctl --user enable --now dispatch-wt-clean.timer`

Script env overrides: `WT_ROOT`, `WT_SALVAGE`, `WT_RETAIN_DAYS`,
`WT_SALVAGE_DAYS`.

## Manual playbook (host near 100%)

1. `df -h` → identify the full filesystem.
2. `sudo du -x -h --max-depth=1 /` → drill into the top consumers.
3. Cheap wins first: stale `/tmp` dirs, journald vacuum, `~/.cache` rebuildables,
   `podman image prune`.
4. Then the policy table above — worktrees, backups, model caches.
5. Watch for "database or disk is full" side effects: podman healthchecks and
   boltdb writes silently stall while the disk is full and stay stale after.
