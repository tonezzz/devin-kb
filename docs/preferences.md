# Preferences

## Communication

- Be concise and direct.
- Use markdown for explanations.
- Prefer minimal code changes; avoid over-engineering.

## Code style

- Follow existing conventions in the current codebase.
- Do not add comments or docstrings unless asked.
- Keep functions small and focused.

## Tools

- Windsurf/Cascade for IDE-based AI coding.
- Devin for autonomous tasks and pull requests.
- GitHub for syncing the knowledge base across machines.

## Upstream contributions

- Do NOT open AI-authored PRs to third-party/upstream repos until Tony
  says so (decided 2026-10-05). Prepare the branch/fork locally, verify
  it, and stop — never submit on his behalf without explicit approval.
- His reasoning: he'd rather be honest that he's learning and slipped
  than look like a noob bothering other people's projects — but he IS
  happy to contribute if a maintainer is receptive. So the posture is
  "ready locally, submit only on request", not "never upstream".
- (First instance: mddb binlog-retention fixes — prepared as
  tradik/mddb#285/#286, then closed unsubmitted; branches kept on
  tonezzz/mddb `upstream/*` and in local `~/CascadeProjects/mddb-fork`.)
