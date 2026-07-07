# Agent Instructions

This file is the single source of truth for any AI agent (Claude Code, Codex, Devin, Windsurf, etc.) that works with this repository or for the user who owns it.

## User context

- The user maintains a personal knowledge base in this repo.
- This repo should be treated as long-lived memory, not a throwaway project.
- Keep articles concise and update them when the user learns something new.

## When to use the KB

- Before answering a question about the user's setup, read `docs/` for relevant files.
- When the user asks you to remember something, prefer adding it to `docs/` or to `.windsurf/rules/` so it persists across sessions and machines.
- When in doubt, update the KB rather than relying on chat memory.

## How to maintain the KB

- One idea per file under `docs/`.
- Use descriptive filenames.
- Commit and push changes to GitHub so they sync to other machines.
