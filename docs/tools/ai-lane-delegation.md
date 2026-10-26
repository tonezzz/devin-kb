# AI lane delegation — routing + go-live procedure (OPS-0823)

The operating procedure that turns the workforce-eval findings
(`ai-workforce-eval.md`) into daily practice: **which lane gets which task
class, what each lane had to pass before it carries real work, and who
babysits**. Card: `ai-lane-delegation-procedure`. Status: LIVE for the
classes marked proven below.

## 1. The lanes

| Lane | What it is | Cost | Surface |
|---|---|---|---|
| **L0 codemod** | deterministic script / mined pattern transform | $0 | runs anywhere, seconds |
| **L1 free** | opencode 1.19.4 + `litellm/gemini-3.5-flash-lite` via LiteLLM proxy on idc03; idc02 is the declared free-lane compute host | ~$0 (Gemini free tier) | `opencode run --model litellm/gemini-3.5-flash-lite --auto`, or kanban script-card → runner-agent |
| **L2 paid** | same opencode harness, paid brain: `or-*` OpenRouter aliases (Gemini flash ~$0.01/task) or `or-claude-fable-5.1`; native Anthropic when `ANTHROPIC_API_KEY` set | cents–dimes | same as L1 |
| **L3 frontier** | Claude Fable 5.1 class — fastest measured model lane | $10/$50 per M tok | same as L1 |
| **L4 Devin** | devin-dispatch worktree sessions (`dispatch-wt-*`) — multi-step, cross-host, judgment | Devin units | kanban `action.type=dispatch` |
| (pending) | OpenHands / IDE surfaces | needs ≥20B-class brain (colab T4 qwen3:8b or paid) | not yet live |

Surfaces are orthogonal to lanes: the same brain can be reached via direct
CLI, a kanban script card (recipe in `ai-workforce-eval.md` §phase 3), or
chat. The kanban card is the audit surface — always the entry point.

## 2. Routing rule — task class → lane

Classify first, then pick the **cheapest lane whose gate the class has
passed**. Never route down-lane to save money on a class that lane hasn't
proven.

| Task class | Route to | Why |
|---|---|---|
| known-pattern code transform (trigger recognized, transform mined, verifier exists) | **L0 codemod** | t1: 7/7 in 0.7s $0 — beats every model on its home turf |
| single-step verifiable op: probe endpoints / write one artifact / list+classify+report, reversible | **L1 free** | o1=1.0, stash-triage COMPLETED in pilot — the proven chore class |
| single-repo grep/read question needing real edits or multi-file reasoning | **L2/L3 paid** | L1 near-misses (6/7) and loops; paid converges (7/7) |
| multi-step remote diagnosis, cross-host, prod-touching, needs judgment | **L4 Devin** | L1 loses the thread after ~3 calls (pilot #1) |
| interactive pairing with Tony / GUI work | IDE surfaces | not live — needs ≥20B brain or paid IDE seat |
| docs/research/reports | L4 (needs rubric judge) or human | scoring differs; no auto verifier yet |

Escalation ladder on gate fail: **L0 → L1 → L2 → L3 → L4 → Tony**.
Two clean failures at one rung = escalate, don't retry the same lane.

## 3. Per-lane go-live gates

A lane may carry real work for a task class only when ALL of these pass:

| Gate | L0 codemod | L1 free | L2/L3 paid | L4 Devin |
|---|---|---|---|---|
| Bench pass on the task class | ≥1 verified transform on the pattern's own task (7/7 t1) | chore corpus pass (o1–o4 @ ≥0.9) | code corpus pass (t1 7/7) | — (the incumbent) |
| Inline verifier exists for THIS run | required | **required** | required | review_kind + verifier or manual check |
| Reversibility / blast radius | dry-run or diff-first | artifact-write only; no prod mutation | artifact-write; prod edits need L4 review | standard dispatch rails |
| Spend headroom | — | free tier alive | OR key under weekly cap / native key present | units budgeted |
| Explicit `target_host` when remote | n/a | required (pilot #1 failed without it) | required | dispatch spec |

Spend gates today: OR key $10/wk cap (hit this week — the 403s), ada Gemini
key $1.3/$10 used; Fable at $10/$50 per M needs an explicit Tony nod for
volume work.

## 4. Delegation protocol

```
card → classify → route → gate → run → verify → escalate/close
```

1. **Card** — every delegated task starts as a kanban card (or comms
   reference to one). Verifier named in the spec: `verifier=<check>`.
2. **Classify** — pick the task class from §2. If unsure between two
   lanes, take the higher one (cheap misroutes cost more than they save).
3. **Route** — L1/L2/L3 direct: `source ~/.config/secrets/litellm-chaba.env`
   + `opencode run --dir <ws> --model litellm/<alias> --auto "<prompt>"`.
   Kanban path: script card `{action:{type:script, host:<runner>,
   script:{repo:chaba, cmd:"echo <b64>|base64 -d|bash"}}}` — seeds on the
   writer, runner-agent claims, result lands in comms.
4. **Gate** — before starting, confirm the lane's §3 gates hold for this
   class TODAY (lane status can regress — spend caps, dead providers).
5. **Run + verify** — the verifier is part of the run, not a separate
   opinion: inline script prints `AGENT_COST_BENCH_RESULT` or the
   artifact contract is checked after. A run without a verifier is a
   test, not a delegation.
6. **Escalate/close** — pass: record score in card comms, close. Fail:
   escalate one rung with the failure evidence attached; two fails at a
   rung → next rung or a Tony decision. Never silently retry.

**Prompt contract for model lanes** (learned in pilots): state the exact
artifact to write, the exact JSON schema, "actually search/probe — do not
guess", and "write the file and stop". Multi-step prompts lose flash-lite
after ~3 tool calls — split or escalate. **Artifact-first variant
(proven 2026-10-24, pilot #3):** when the model keeps stopping before it
writes, instruct it to WRITE the artifact skeleton FIRST ("STEP 1: write
verdict.json with null fields"), then search, then rewrite it filled —
write-then-fill survives the early-stop failure mode where
search-then-write does not.

## 5. Go-live matrix (proven as of 2026-10-24)

| Lane × class | Status | Evidence |
|---|---|---|
| L0 × pattern fix (t1-class) | **LIVE** | 7/7, 0.7s, $0 (OPS-0809 pattern bench) |
| L1 × single-step probe/write/report | **LIVE (gated)** | o1 1.0 eval cell; pilot #2 stash-triage COMPLETED; pilot #3 traffic-report verdict correct on retry (run 1 stopped before artifact — artifact-first prompt contract fixed it) |
| L1 × multi-step remote diagnosis | **NOT LIVE** | pilot #1: stopped after 3 calls, conversational reply; host-mismatch without explicit target_host |
| L1 × code-with-test | **NOT LIVE** | 6/7 near-miss, never converges (loops on self-verify) |
| L2 OR-gemini × code-with-test | **LIVE (gated)** | t1 7/7 2/2 clean; m1 real Go edits (verifier compile-boundary is the blocker, not capability) |
| L3 Fable × code-with-test | **LIVE (gated)** | t1 7/7 in 60s (fastest), o1 1.0 in 13s; m1 capability confirmed vs behavioral verifier |
| L4 Devin × multi-step/prod | **LIVE** | ada-memory-sync resolved end-to-end (9 conflicts → green) |
| OpenHands/local-CPU × anything | **NOT LIVE** | gpt-oss schema-misaligned, hermes3 no tool calls, 8B CPU too slow; needs T4 + qwen3:8b |

## 5b. Tool surface per lane (added 2026-10-26, AUD-0886)

Lanes pick the *brain*; MCP servers are the *hands*. Tool-surface rules:

- **Every lane: schema weight is spend.** Each configured MCP server injects
  its full tool schema into the model's context every session. alphavantage
  alone is ~5.6k lines (~15k tokens). Keep `mcp_config.json` lean; push
  rarely-used servers behind `mcp-allowlist.py` or per-task profiles.
- **L0/L4 diagnostic surface**: `mcp-debug` (compact multi-host commands,
  measured token savings) + `mcp-health` (service health, alerts,
  auto-recovery). Prefer these over raw ssh for fleet ops — the compact
  output IS the token save.
- **Knowledge/memory**: `mddb` (doc store, semantic search, ada banks),
  `mcp-weaviate` (chaba repo corpus). Rule: weaviate = chaba code/SSOT,
  mddb = everything else.
- **Execution/control**: `postgres` (read-only queries), `github` (repo
  ops), `playlive` (browser verify — the consumer-surface proof the
  OPS-0731 rule demands), `mcp-colab` (local-gpu-packs control plane).
- **Domain tools** (gate by task): `yomi` (LINE), `docs-trade` (trade docs),
  `alphavantage` (market data — allowlist core fns), `mcp-gpu` (GPU/imagen),
  `notebooklm` (when repaired).
- **Dead/retired as of audit**: home-assistant, michael-ha, michael-dev,
  workflows, docs, notebooklm all fail `mcp_list_tools`; mcp-llama is
  superseded by the LiteLLM gateway. Full verdicts: `mcp-fleet-audit.md`.
- **Cheap lanes get cheap tools.** An L1 run should not be given a 30-tool
  playlive schema it will never call — tool exposure follows the run's
  verifier contract, not the global config.

## 6. Babysitting / verification roles

- **Inline verifier** (script, deterministic): mandatory on every model-lane
  run. This is what makes cheap lanes viable — weak model + strong gate =
  safe labor.
- **Dispatcher** (any Devin/Ada session): classifies, routes, checks gates,
  writes results to card comms. Owns the escalation decision.
- **Runner-agent** (idc02/dell): executes script cards; no judgment —
  satisfiability of `action.labels` is an ops duty (kanban-throughput
  procedure).
- **QC layer**: `devin-session-audit` (artifact landing), QC scoreboard
  `reopen_events` (stomps/regressions), key-watch (lane spend/quota).
- **Tony gates**: spend raises, prod changes without precedent, ambiguous
  direction — board request, not a silent lane pick.
- Metric that matters: **babysitting minutes per task** — a $0 lane that
  needs 20 min of human untangling is more expensive than a paid one.
