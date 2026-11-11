#!/usr/bin/env bash
# clean-dispatch-worktrees.sh — standard dispatch/Devin worktree retention.
#
# Policy (see devin-kb docs/tools/host-disk-retention-cleanup.md):
#   - a worktree is eligible only if NO file inside was modified within
#     WT_RETAIN_DAYS (default 7) — protects active sessions
#   - clean worktrees are removed via `git worktree remove` (never rm -rf;
#     git itself refuses dirty/locked worktrees)
#   - dirty worktrees are tarred to WT_SALVAGE with .status/.head manifests,
#     then force-removed — nothing is unrecoverable
#   - salvage artifacts expire after WT_SALVAGE_DAYS (default 30)
#
# Env overrides: WT_ROOT, WT_SALVAGE, WT_RETAIN_DAYS, WT_SALVAGE_DAYS
set -uo pipefail
ROOT="${WT_ROOT:-$HOME/CascadeProjects}"
SALVAGE="${WT_SALVAGE:-$HOME/wt-salvage}"
RETAIN_DAYS="${WT_RETAIN_DAYS:-7}"
SALVAGE_DAYS="${WT_SALVAGE_DAYS:-30}"

[ -d "$ROOT" ] || exit 0
mkdir -p "$SALVAGE"
cd "$ROOT" || exit 1

for d in dispatch-wt-*/; do
  d=${d%/}
  [ -d "$d" ] || continue
  if find "$d" -newermt "$RETAIN_DAYS days ago" -print -quit 2>/dev/null | grep -q .; then
    echo "SKIP(<${RETAIN_DAYS}d): $d"; continue
  fi
  if [ ! -f "$d/.git" ]; then
    echo "SKIP(nongit): $d"; continue
  fi
  repo=$(sed 's|^gitdir: \(.*\)/.git/worktrees/.*|\1|' "$d/.git")
  if git -C "$repo" worktree remove "$PWD/$d" 2>/dev/null; then
    echo "REMOVED clean: $d"
  else
    git -C "$d" status --porcelain > "$SALVAGE/$d.status" 2>/dev/null
    git -C "$d" log -1 --format="%H %D %s" > "$SALVAGE/$d.head" 2>/dev/null
    tar czf "$SALVAGE/$d.tgz" "$d" 2>/dev/null
    if git -C "$repo" worktree remove --force "$PWD/$d" 2>/dev/null; then
      echo "REMOVED dirty(salvaged): $d"
    else
      echo "FAILED: $d"
    fi
  fi
done

# prune stale worktree metadata in every sibling repo
for r in */; do
  [ -d "$r/.git" ] && git -C "$r" worktree prune 2>/dev/null
done

# expire salvage artifacts
find "$SALVAGE" -type f -mtime "+$SALVAGE_DAYS" -delete 2>/dev/null
exit 0
