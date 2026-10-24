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

**Free-brain inventory (probed 2026-10-23, LiteLLM proxy on idc03):**

| Model group | Backend | Status |
|---|---|---|
| `bench` → gemini-3.5-flash-lite | Gemini free tier | ✅ ALIVE — the workhorse (chores 1.0, code intern-grade) |
| `tool-call`,`chat-local`,`summary`,`voice-aux`,`classify` | local smalls (llama3.2-class) | ✅ ALIVE — too weak for agents; fine for classify/summarize |
| `ollama-qwen7b` → qwen2.5:7b | Ollama quadlet on idc02 (`:11434`) | ✅ ALIVE but CPU-slow — couldn't finish OpenHands turn 1 in 5min |
| `gemini-2.5/3.5-flash(-lite)` direct | Gemini project | ❌ monthly spend cap |
| `or-*` | OpenRouter | ❌ key weekly cap (resets ~Oct 26) |
| `colab-gemma3` → gemma3:12b | Colab T4 reverse-SSH | ❌ session dead (ephemeral by design) |

Upgrade paths for a real code brain: pull qwen2.5-coder:14b on idc02
(~9GB — tight vs resident 6.8G ollama + services), wake the Colab worker,
or raise the OpenRouter cap (cheapest paid). idc02 is the declared
"free-lane compute OFF prod host" per the litellm config comment.

**Local-brain attempts (2026-10-23, omen Ollama 0.40.3):**
- `gpt-oss:20b` (13.8GB, ~5.7 tok/s CPU): emits tool calls at raw
  `/api/chat` AND `/v1` level, but inside opencode it hallucinates
  Claude-Code tool names (`repo_browser.apply_patch`, `assistant.bash`)
  that don't exist in opencode's headless toolset → loop dies. Not viable
  until schema-aligned.
- `hermes3:8b`: responds through proxy alias but emits no tool calls
  (writes "let me provide a function call" as text).
- `gemma3:12b` (omen AND Colab notebook model): **official Ollama registry
  build has NO tool support** — GitHub issue ollama/ollama#9680: Google
  didn't train gemma3 for tools; Ollama maintainers refuse to add the tag.
  Community workaround exists: `PetrosStav/gemma3-tools` template.
  ⚠️ The colab notebook serves gemma3:12b — agent loops will fail on it
  unless the worker pulls qwen3 instead.
- **`qwen3:8b` — the winner so far (GitHub-recommended: thinking+tools).**
  Pulled on omen (5.2GB). Emits tool calls via `/v1` (what opencode uses)
  and through the LiteLLM proxy (`ollama-qwen3` alias, added to idc03
  config + gateway restarted). In opencode it correctly calls the `write`
  tool with proper content — first local model to align with opencode's
  schema. Two quirks: (1) thinking-mode eats the token budget on short
  requests (`think:false` fixes; tool calls still emitted with thinking
  on); (2) wrote to `/hello.py` (fs root) instead of workspace cwd —
  prompt-phrasing issue, not capability. **Testing on real eval task t1
  now (`config.qwen3.yaml`).**
- Litellm gateway on idc03 now carries aliases: `ollama-gemma12b`,
  `ollama-hermes8b`, `ollama-qwen3` (all → omen 100.75.102.88:11434),
  backed up config before edits, validated YAML, container restarted,
  health 200.
- ⚠️ **Colab notebook must serve qwen3:8b, not gemma3:12b** — change
  `MODEL = "qwen3:8b"` on line 30 of `colab-serve-worker.ipynb` (already
  listed as an alternative; ~5GB, fits T4 15GB, tool-capable). gemma3
  official build has no tools → agent loops fail even on the GPU.
- t1 result with qwen3:8b on omen CPU: **0.857 (6/7) with ZERO edits** —
  one reasoning step (484 reasoning tok), no tool calls, then stopped.
  Same near-miss score as flash-lite but *without attempting a fix*.
  CPU-bound 8B is too slow to sustain opencode's agent loop. The T4 GPU
  version is the actual test.

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

## Pilot results (2026-10-23, code class, gemini-3.5-flash-lite)

`~/evals/results/20261023_084244_85baf9.json` — 4 code tasks × 2 tools = 8
cells, all 8 timed out at 30min (0/8 gate). Manual follow-up on the timeouted
workspaces:

- **t1 opencode (manual gate): 6/7** — made a real, more careful edit this
  time (`intersects` + per-point `covers` on STRtree) but it raised IndexError
  at runtime → held-out test caught it. Same near-miss class as the smoke
  test's `covers` swap. **flash-lite finds the file, writes a plausible fix,
  the gate catches it — consistently, both times.**
- t1 openhands: timeout, no edits. t2 both: timeout, openhands no edits.
- m1/m2 (Go): timeout both tools — replication tasks too heavy for the lane.
- Conclusion: on flash-lite, the code class does NOT converge (loops on
  self-verification until killed — wall-clock control is a real metric, not a
  test artifact). The lane's ceiling: chores (3/4 @ 1.0, see ops run) +
  test-gated single-line near-misses. Code needs a ≥12B GPU brain or paid.

## Colab GPU lane (gemma3:12b on T4)

Turnkey config: `~/evals/config.colab.yaml` (validated) — t1 + o1 × opencode +
openhands. Requires `colab-serve-worker.ipynb` tunnel UP on idc03
(`127.0.0.1:11434` ← Colab Ollama, reverse-SSH as colabtun) and the notebook's
`/model/new` cell registering `colab-gemma3` on the LiteLLM proxy. Model:
gemma3:12b (~8GB q4, fits T4 15GB). Watch: `ss -tln | grep 127.0.0.1:11434` on
idc03, or probe `curl http://127.0.0.1:11434/api/version` there.

## Pattern-match coding direction (2026-10-24, OPS-0809)

Tony hypothesis: much of agent coding = pattern match + replace/connect.
Plan: pattern library mined from repo history (leak-safe, no benchmark-task
commits) → JEV matcher (semantic top-k over triggers; jev-student live on
idc03 :8778) → hint mode (pattern in agent prompt) + codemod mode
(deterministic; t1 covered_by first) → bench arms 0-3 on the existing
corpus with same gates → every verified fix mined back (P5). Key question:
does a hint move t1 6/7 → 7/7, and at what cost? Seed mine started:
`~/evals/patterns/mine-1.jsonl` (10+ records).

### Pattern bench first results (2026-10-24, OPS-0809)

t1 arms (terrology elevated-geom predicate fix):
- arm0 agent alone (flash-lite): 6/7 — near-miss `covers` or timeout
- arm1 agent + pattern hint: 6/7 BUT correctly localized (glob→grep the
  predicate) then stopped — hint fixes localization, not completion
- arm2 deterministic codemod: **7/7 in 0.7s, $0** — pattern hypothesis
  confirmed at its strongest case; codemod encodes exact semantics where
  models near-miss
- arm3 JEV-routed: next
Pattern store: mddb `code-patterns` (seeded from mine-1.jsonl). Lessons:
verify-venv deps must declare runtime libs; opencode provider registry
clobbered by testing causes phantom proxy errors. Bench file:
`~/evals/patterns/bench-t1-results.md`.

### t1 corrected head-to-head (2026-10-24, OR rerun clean)

| lane | result | time | cost |
|---|---|---|---|
| flash-lite agent | 6/7 (`covers` fails — excludes everything) | 167s+ | ~$0 |
| qwen3/gpt-oss local CPU | 6/7 (no edit) | 9-273s | $0 |
| OR gemini-3.5-flash agent | **7/7 (2/2 PASS)** | 218-275s | ~$0.01 |
| deterministic codemod | **7/7** | 0.7s | $0 |
| JEV-routed (arm3) | **7/7** | ~2s | $0 |

Nuance: the pattern encodes the PROPERTY (boundary-touching covered cells
count), not one literal string — the gate accepts both `intersects` and
`covered_by`; `covers` and `within` both fail. The paid model independently
found `intersects` (r1) and `covered_by` (r2).

### Pattern library growth (2026-10-24)

- mddb `code-patterns` collection: 4 seeded patterns (3 Go + 1 Python),
  each with trigger/class/transform/commit + codemod-verified flag.
- Mine expansion: chaba + ada-voice = feature-dense, few fix+test pairs
  (3 candidates). mddb-fork deep mine = replication-class dense (4/6
  commits) — the natural lane-classifier seed ("replication" vs "other").
- Classifier training data = trigger→class pairs from mines
  (train-minilm-clf.py pipeline). Small initial set; grows via P5
  (every verified fix mined back).

### M1 verifier coupling (2026-10-24)

M1 held-out tests reference the ORIGINAL fix's internals (`rc.connected`,
`rc.lagMs`, `rc.applier`) — a behaviorally-correct divergent fix
(agent used `streamConnected` + `IsHealthy`) compiles-fails. Handler test
also type-coupled (`ReplicationLag *int64` vs untyped int). Attempted an
interface-agnostic behavioral test: client-contract part works, but the
handler needs a live-leader mock that doesn't exist — proper fix = new
M1-behavioral task with a mockable interface. Recorded as design
limitation, not model failure. The paid m1 Go edits are capability
evidence regardless.

### Voice Tier-1 LIVE (2026-10-24, ADA-0816 done)

Fully-local voice loop on omen proven from an iPhone: MediaRecorder webm
→ ffmpeg decode → faster-whisper STT → hermes3:8b (Ollama) → Piper TTS →
audio back on phone. URL https://tony-omen.taila0626a.ts.net/ (tailscale
HTTPS = secure context for mic). Runs as systemd `voice-miniapp` on omen
(~/voice-miniapp/{server.py,index.html}), ada-whisper venv. $0, zero cloud.
iOS gotchas solved: AudioContext forced sampleRate rejected by Safari;
ScriptProcessor flaky → MediaRecorder + server-side ffmpeg. Card ADA-0816.
Upgrade path: T4 + qwen3:8b for speed/Thai (roomkit VRAM table: 8GB→qwen3:4b,
omen 4GB is the floor).

### Voice P0 DONE (2026-10-24, ADA-0817 closed)

Full-duplex-ready voice mini-app verified by Tony: VAD auto-endpoint
(900ms), Thai STT in, forced-English clean TTS out, streaming 160ms PCM
chunks + turn IDs + barge-in (tap during playback = instant stop).
Bugs fixed: Piper `AudioChunk.audio_int16_bytes` (not `.audio`); Thai in
HTTP headers → latin-1 UnicodeEncodeError (URL-encode X-Transcript/X-Reply);
English voice mangling Thai (force English replies; Thai Piper voice
th_TH-tsync2 downloaded but needs tltk+pandas — follow-up). Next: P1
speculative ASR (Moonshine Tiny) + adaptive endpointing table; Thai voice
install.
