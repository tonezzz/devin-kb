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
- chores/ops (built: O1–O4 in `~/evals/tasks/`, config `~/evals/config.ops.yaml`):
  - `o1-endpoint-health` — probe 3 HTTP endpoints → `health.json`; verifier
    re-probes live and compares (reachable + status code, incl. the reachable-404 case)
  - `o2-yaml-config` — write `service.yaml` changing 2 fields, preserving the rest;
    verifier parses YAML, scores changes + untouched-value preservation
  - `o3-log-triage` — analyze embedded 184-line log → `triage.txt`
    (total_lines, error_count, top_error_service); deterministic truth
  - `o4-systemd-state` — `systemctl is-active` 3 units → `units.json`;
    verifier re-queries systemctl live (covers a real ops-chore class)
- docs/research: different scoring (rubric/judge)

## Key principle (proven 2026-10-23)

**Verification makes cheap lanes viable.** Weak model + strong test gate = safe
cheap labor. flash-lite produced a plausible-but-wrong fix (`covers` vs
`covered_by`) and the gate caught it. The eval question per lane is not "is the
model good" but "what's the cheapest lane that passes the gate for this task
class".

## Phases

1. Pilot (running): opencode vs openhands × 4 code tasks × flash-lite — baseline table
2. ✅ Ops corpus built (2026-10-23): O1–O4 all validated + verifiers
   bidirectionally tested; queued behind pilot (`config.ops.yaml`)
3. Surface adapters: task.yaml → surface input → run → verify → report back
   - ✅ **kanban free-lane cell LIVE (2026-10-23):** card `eval-o1-opencode`
     — writer-seeded script card → queued → runner-agent on idc02 claimed →
     opencode 1.19.4 + gemini-3.5-flash-lite (LiteLLM proxy) ran the real
     o1-endpoint-health task → inline verifier scored **1.0** → result in
     card comms → done. ~2min, $0. idc02 now carries opencode +
     `~/.config/opencode/opencode.json` (litellm provider) +
     `~/.config/secrets/litellm-chaba.env`.
     Recipe: `action:{type:script, host:idc02, script:{repo:chaba, cmd:"echo
     <b64> | base64 -d | bash", timeout:N}}` + `queue` via `/action`. The b64
     script sources secrets, runs the agent, then a verifier printing
     `AGENT_COST_BENCH_RESULT` — score lands in comms via do=finish.
     `/card` API gates `action.type` to dispatch|manual → script cards seed
     on the writer checkout (precedented: OPS-0173).
   - chat msg → runner → reply with result + verify status
   - WP CPT post = task spec; comment = agent result + score
   - chat msg → runner → reply with result + verify status
   - WP CPT post = task spec; comment = agent result + score
4. Deliverable: **routing matrix + fallback ladder** in devin-kb — per task class,
   cheapest→richest lanes that pass the gate, with cost/task and babysitting
   minutes (the hidden cost of cheap AI)

## Metrics per cell

pass rate (gate) · cost/task · wall-clock · tokens · human interventions ·
unrelated-test breakage · babysitting minutes per task
