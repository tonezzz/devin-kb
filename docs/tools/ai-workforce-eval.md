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
4. Deliverable: **routing matrix + fallback ladder** in devin-kb
   — DONE 2026-10-24:  (routing rule, per-lane
   gates, delegation protocol, go-live matrix, babysitting roles) — per task class,
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

### Voice P1 parked (2026-10-24)

Speculative ASR (Moonshine Tiny) evaluated: installed but API is finicky
(model_path/download helpers), and true speculative pre-inference needs a
WebSocket streaming architecture (client sends audio during recording →
server pre-warms LLM). ROI vs the working tap-once + auto-endpoint lane:
not justified on omen CPU. DECISION: park P1; accept 15-20s CPU thinking
as the rainy-day floor until a T4/GPU worker is available.

### Lane delegation pilot (2026-10-24, OPS-0823) — sharpened boundaries

Two real chores delegated per the new procedure:
1. **timer-alert-idc03-ada-memory-sync** (multi-step remote diagnosis) —
   free lane FAILED (flash-lite did 3 bash calls then stopped with a
   conversational reply; run 1 also had a host mismatch). Human diagnosis
   completed: the unit exits 1 BY DESIGN when vault-vs-MDDB conflicts
   exist; 9 real conflicts pending since 10-16 (persona/self, people/kk,
   assets/*); the alert is correct, needs a Tony decision (take-remote /
   take-vault / per-item). Recorded on the card with options.
2. **stash-graveyard-triage** (single-repo list+classify+report) —
   COMPLETED: all 7 stashes droppable (6 stale metadata, 1 already merged
   into live assessment; sprawl 13->6 branches, 20->8 worktrees).
   CLOSED as done.

**Sharpened lane boundaries (the real deliverable):**
- Free lane (flash-lite) carries: single-step verifiable ops (probe/write/
  report), single-repo list+classify+report. VERIFIED in pilot.
- Free lane CANNOT carry: multi-step remote diagnosis (loses thread) —
  route to L2 paid or a step-script harness.
- Delegations need explicit `target_host` (agent host != target host).
- Some "failures" are correct alerts (exit-1 by design) — diagnosis must
  distinguish bug from intended signal.

### Fable 5.1 bench (2026-10-24) — L3 proven

Minimal run (t1 + o1, opencode, 1 repeat): **2/2 PASS in 60s**.
- o1 = 1.0 (13s); t1 = **7/7 (60s)** — within→covered_by WITH explanatory
  comment (exact semantic fix; 4x faster than Gemini OR 218-275s).
- t1 head-to-head: flash-lite 6/7 (167s+), local CPU 6/7 no-edit, Gemini OR
  7/7 (218-275s), **Fable 7/7 (60s)**, codemod 7/7 (0.7s $0).
- L3 frontier lane proven. Full matrix (m1, repeats, openhands) = 
  config.fable-or.yaml, ready. Route: or-claude-fable-5.1 on LiteLLM proxy.

### Fable m1 result (2026-10-24)

0/2 on the old coupled gate. CORRECTED by the m1-behavioral rescore
(see below + `~/evals/m1-behavioral-rescore-20261024.md`): r1 wired the
handler correctly (`Healthy: replClient.IsHealthy()`) and passes the
behavioral gate **1.0** — the old verifier's compile-boundary was a
false negative. r2 made **zero code edits** (the "131-line
handlers+client" figure was the injected held-out test diff, not agent
work). Verdict: Fable Go capability confirmed at 1.0 on a real attempt;
M1 verifier was the blocker, now fixed. Burn: ada key ~$10 weekly cap
EXHAUSTED as of ~16:55 (402 on the m1-behavioral rerun) — paid lane down
until reset (~Oct 26) or key raise.

### FIRST REAL JOB DONE (2026-10-24) — timer-alert resolved

ada-memory-sync unit GREEN (Result=success, ExecMainStatus=0) after 8
days of daily failures. Resolution: --take-remote pulled curated remote
versions for all 9 conflicts (backup: /tmp/ada-memory-backup-*); 0
conflicts remain. Closed the alert card. This ran end-to-end through the
delegation procedure (OPS-0823): classify → per-item decision → route →
verify (unit exit 0). The procedure works on real production work.

### M1-behavioral verifier (2026-10-24) — strictly better, catches real bug

Built `~/evals/tasks/m1-behavioral/`: held-out test asserts the HTTP
contract (follower with unhealthy client must NOT report healthy:true),
using public API + the repo's own handler-test helper. Bidirectional
(independently re-verified, dispatch idc02): parent scores 0.5 (bug
caught), real fix c0850f0 = 1.0.

CORRECTED m1 retrospective (rescore of all attempt workspaces):
paid lane = **3/4 real attempts fully correct** (fable-r1, or3-r1,
or-openhands — all wire `Healthy` from client state), 1/4 real partial
(or3-r2: client fixed, handler never wired — the one true "wiring gap").
3 more runs made no edits (fable-r2, or-opencode, fresh m1beh run that
died on OR 402) → baseline 0.5 each. Old verifier recorded 0/7 —
compile-boundary conflated with capability.

Subtleties the rescore surfaced:
- Parent `IsHealthy()` exists but uses time-since-last-entry — the
  semantics the prompt explicitly bans (idle caught-up follower must
  stay healthy). Real fix = connected+lag semantics AND handler wiring.
- Behavioral test does not yet cover the idle-healthy case — residual
  gap; an impl could pass while still being time-based.
- Harness bug found: verifier injects tests by filename → clobbers
  tracked repo tests (replication_handlers_test.go etc.) and residue
  contaminates later scoring. Needs unique inject names or
  snapshot/restore. m2 has same pattern — needs m2-behavioral.
### T4 live lane (2026-10-24) — GPU confirmed NOT the code-lane gap

colab-qwen3 tunnel UP (UFW port-22 fix + new-key authorization were the
blockers), qwen3:8b served on the T4. config.colab-live.yaml run: **0/4**
— same as omen CPU (zero edits, baseline 6/7). CONFIRMED: local-lane code
gap = model capability, not hardware. GPU helps only with a capable model
(gpt-oss:20b would be the T4 upgrade). Ladder stands: local = chores +
codemod; code = paid (Fable) or capable open model.

### lesson-polish (2026-10-24, OPS-0829 + KNB-0830)

Education CPT audit built + first scan: 66 lessons, 44 flagged
(27 R3 decision-no-pointer, 10 R1 overdue, 4 R4 orphan, 2 R2 junk).
Door gaps found: /lesson has no delete op (junk probes stuck; Cloudflare
blocks WP DELETE 403/1010 → KNB-0830); re-file preserves next_review
(overdue = due-for-review queue, needs review-date override to advance).
Arm A (audit accuracy): deterministic vs flash-lite on 5 samples,
Jaccard 0.31 — deterministic = precision, agent = recall+false-pos.
Hybrid wins: deterministic scan + agent review + human gate. Junk
lessons id 2259/2261 (speed-probe probes) flagged for deletion.

### lesson-polish execution (2026-10-24)

Door changes shipped (246481a9e): lesson delete op (guarded devin/tony)
+ next_review override. Review queue: 9/9 overdue advanced to 2026-11-07
(verified). Blocked: junk deletion (WP-origin lesson CPT lacks DELETE
route + private-only status — origin gap, same as OPS-0820); Fable polish
(OR 402 weekly cap, resets Oct 26). Arm A: Jaccard 0.31 deterministic vs
agent; hybrid wins. Delete op ready for when origin registers it.

### JEV = umbrella term (2026-10-24, Tony)

In the ada-nest system, **JEV** is the umbrella term for the task-routing /
lane-selection layer: any cheap classifier that decides which brain/lane
handles a task (noul gates, decision classifiers, the cascade router).
Tony: "it's actually the vital component." The cascade (BEN-0811) is the
architecture; JEV is the router at its center. Current JEV instances:
jev-student (noul gate, :8778), decision-arena bench (laya 0.704 on 27
cases), jev-triage pack, and the lesson-audit hybrid (deterministic gate +
agent recall). The rainy-day question per task: "cheapest lane whose
output passes the gate" — JEV picks the lane, the gate verifies.

### lesson-polish nest pack (2026-10-24)

Drive pack `lesson-polish` shipped (runs on any worker): deterministic
R1-R5 audit → out/lesson-audit-*.json. Standalone verified: 68 lessons,
39 flagged (R3=27, R5=20 soft, R4=4, R2 thin=2). 4 lessons
deterministic-polished with KB pointers ($0); 9/9 review dates advanced.
Remaining 27 R3 = Fable polish queue (post-OR-reset). JEV = umbrella
term for routing/lane-selection in ada-nest (KB).
