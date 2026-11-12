#!/usr/bin/env bash
# git-worktree-gc.sh — generic stale-worktree garbage collector.
#
# Supersedes clean-dispatch-worktrees.sh (which only matched
# dispatch-wt-*). Iterates `git worktree list` on each repo in
# WT_GC_REPOS, so it catches named session worktrees, detached
# checkouts, and eval artifacts — not just dispatch dirs.
#
# Safety:
#   - always runs `git worktree prune` first (drops /tmp tombstones)
#   - never touches the main worktree or the caller's own cwd
#   - clean worktrees removed via `git worktree remove`
#   - dirty worktrees older than retention are tarred to
#     $WT_SALVAGE (minus .git) then force-removed — recoverable
#   - salvage artifacts expire after WT_SALVAGE_DAYS
#
# Env: WT_GC_RETAIN_DAYS=7  WT_SALVAGE=~/wt-salvage
#      WT_SALVAGE_DAYS=30   WT_GC_REPOS="~/CascadeProjects/chaba ..."
#      DRY_RUN=1 to report without removing
set -u
RETAIN="${WT_GC_RETAIN_DAYS:-7}"
SALVAGE="${WT_SALVAGE:-$HOME/wt-salvage}"
SALVAGE_DAYS="${WT_SALVAGE_DAYS:-30}"
REPOS="${WT_GC_REPOS:-$HOME/CascadeProjects/chaba $HOME/CascadeProjects/ada-voice}"
DRY="${DRY_RUN:-0}"
SELF="$(cd "$(dirname "$PWD")" && pwd)/$(basename "$PWD")"
mkdir -p "$SALVAGE"

for repo in $REPOS; do
  [ -e "$repo/.git" ] || continue
  git -C "$repo" worktree prune
  git -C "$repo" worktree list --porcelain | awk '/^worktree/{print $2}' | while read -r wt; do
    [ "$wt" = "$repo" ] && continue                      # main worktree
    [ "$wt" = "$SELF" ] && { echo "SKIP self: $wt"; continue; }
    [ -d "$wt" ] || continue                             # pruned above
    # age = most recent activity: last commit ts vs dir mtime
    c_ts=$(git -C "$wt" log -1 --format=%ct 2>/dev/null || echo 0)
    d_ts=$(stat -c %Y "$wt")
    [ "$d_ts" -gt "$c_ts" ] && c_ts=$d_ts
    age_s=$(( $(date +%s) - c_ts ))
    [ "$age_s" -lt "$((RETAIN*86400))" ] && continue     # still active
    dirty=$(git -C "$wt" status --porcelain 2>/dev/null | wc -l)
    if [ "$dirty" -eq 0 ]; then
      [ "$DRY" = 1 ] && { echo "WOULD-RM clean: $wt"; continue; }
      git -C "$repo" worktree remove "$wt" 2>/dev/null \
        && echo "REMOVED clean: $wt"
    else
      tag=$(basename "$wt")-$(date +%Y%m%d)
      [ "$DRY" = 1 ] && { echo "WOULD-SALVAGE dirty($dirty): $wt"; continue; }
      if tar czf "$SALVAGE/$tag.tgz" -C "$wt" --exclude=.git . 2>/dev/null \
         && git -C "$repo" worktree remove --force "$wt" 2>/dev/null; then
        echo "REMOVED dirty($dirty,salvaged): $wt"
      else
        echo "FAILED dirty: $wt (left in place)"
      fi
    fi
  done
done
find "$SALVAGE" -name "*.tgz" -mtime "+$SALVAGE_DAYS" -delete 2>/dev/null
