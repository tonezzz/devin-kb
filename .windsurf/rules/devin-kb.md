---
trigger: always_on
description: Load the user's personal knowledge base from ~/devin-kb whenever it is available.
---

# Personal Knowledge Base

You should always consider the user's personal knowledge base when answering questions or making decisions. The KB is stored at `~/devin-kb` (or the current workspace if it is the KB repo itself).

## What to do

- If the user asks something about their setup, preferences, workflows, or projects, check the `docs/` folder in the KB repo for relevant articles.
- Prefer concise, accurate answers based on the KB contents.
- If the KB is missing information the user needs, offer to update the KB so it stays useful across machines.

## Structure

- `docs/general.md` — high-level facts about the user and their workflows.
- `docs/preferences.md` — coding style, communication preferences, and tools.
- `docs/tech-stack.md` — technologies, frameworks, and infrastructure the user uses.
