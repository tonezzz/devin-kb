# AI workforce eval — surfaces × brains × task classes

The bigger question behind the coding-agent eval (see `agentic-ai-coding-ides.md`):
not "which tool wins" but **which (surface × brain × task class) lane carries real
work at acceptable cost** — so when a paid lane gets capped/expensive, work
re-routes instead of stalling. Rainy-day planning.

## Axes

### Surfaces (how work reaches the agent)

| Surface | Stack component | Natural fit |
|---|---|---|
| IDE chat | Devin Desktop, Antigravity | deep work, review-heavy |
| CLI headless | `opencode run`, `openhands --headless`, `devin` CLI | autonomous jobs, CI-style |
| Async dispatch | `dispatch-wt-*` worktree pattern (chaba) | fire-and-forget lanes |
| Kanban | chaba kanban → card pickup | org layer: queue/priority/audit |
| Chat/voice | ada-voice, yomi/LINE, telegram bots | quick ops: "restart X" |
| WP CPT + comments | wp-boards: post=task, comments=agent dialogue | human-readable audit |

### Brains (cost ladder)

paid frontier (Devin/SWE-2, Claude, GPT, Gemini paid)
→ cheap cloud (gemini-3.5-flash-lite via LiteLLM `bench`, OpenRouter budget)
→ free local (ollama llama3.2:3b / qwen7b, colab-gemma3 — asleep?)

### Task classes

- code-with-test (built: T1/T2/M1/M2 in `~/evals/tasks/`)
- chores/ops: restart service, update SSOT field, health check — needs new verifiers
- docs/research: different scoring (rubric/judge)

## Key principle (proven 2026-10-23)

**Verification makes cheap lanes viable.** Weak model + strong test gate = safe
cheap labor. flash-lite produced a plausible-but-wrong fix (`covers` vs
`covered_by`) and the gate caught it. The eval question per lane is not "is the
model good" but "what's the cheapest lane that passes the gate for this task
class".

## Phases

1. Pilot (running): opencode vs openhands × 4 code tasks × flash-lite — baseline table
2. Corpus expansion: chore/ops tasks with real verifiers (health endpoint, schema check)
3. Surface adapters: task.yaml → surface input → run → verify → report back
   - kanban card body = prompt; verifier hooks existing dispatch pipeline
   - chat msg → runner → reply with result + verify status
   - WP CPT post = task spec; comment = agent result + score
4. Deliverable: **routing matrix + fallback ladder** in devin-kb — per task class,
   cheapest→richest lanes that pass the gate, with cost/task and babysitting
   minutes (the hidden cost of cheap AI)

## Metrics per cell

pass rate (gate) · cost/task · wall-clock · tokens · human interventions ·
unrelated-test breakage · babysitting minutes per task
