# Agentic AI coding IDEs & eval

Landscape notes + how to benchmark agentic coding tools. Compiled 2026-10-23.

## Google Antigravity

Google's agentic development platform (Gemini 4 / 3.8 models). Not just an IDE — multiple surfaces:

- **App** — desktop agent manager, parallel agents across workspaces, scheduled tasks
- **IDE** — standalone agentic editor (macOS/Windows/Linux)
- **CLI** — terminal-first agent
- **IDE extensions** — VS Code, JetBrains, Visual Studio, Zed, Xcode
- **SDK** — Python API for building agents on their harness

Site: https://antigravity.google/

### Pricing (individual)

| Plan | Price | Limits |
|---|---|---|
| Free | $0 | Weekly quota refresh, basic rate limits, unlimited Tab completions |
| Google AI Pro | ~$20/mo | Larger quota, 5h refresh, higher weekly cap |
| Google AI Ultra | $100/mo | ~5x Pro tokens |
| Google AI Ultra (top) | $200/mo | ~20x Pro, third-party models |
| Business | via Google Cloud | Gemini Enterprise |

- Quota is "work done" weighted, not per-prompt. Complex tasks burn more.
- Paid tiers also have a hard weekly cap — heavy nonstop use still throttles.
- Overage on paid tiers = purchased AI credits at Gemini Enterprise rates.

## Surfaces per tool (which slots each fills)

| Tool | Surfaces | Free lane? |
|---|---|---|
| Devin | Desktop, CLI (`devin -p`), web, MCP | paid (rate-limited) |
| opencode | TUI (primary), desktop app, `serve` web UI, VS Code ext, Zed via ACP | yes + BYOK |
| OpenHands | web GUI (watch agent drive editor/terminal/browser), VS Code ext, CLI, SDK, GH Actions | yes + BYOK |
| Antigravity | standalone IDE + agent mgr + CLI + extensions + SDK | free weekly quota |
| Zed | Rust editor, built-in agent panel (ACP hosts opencode) | free editor |

Free IDE-ish lane = **Zed + opencode/ACP** or opencode desktop. Watch-an-agent-work = OpenHands web GUI. Only true agent-first IDE = Antigravity.
Setup cards on the board: OPS-0795 (opencode interactive ~10min), OPS-0796 (Zed+ACP ~30-60min), OPS-0797 (OpenHands GUI ~30min), OPS-0798 (Antigravity ~30min + Google login).

## Dev flow: Devin vs Antigravity-style

| | Devin (current setup) | Antigravity |
|---|---|---|
| Primary unit | Conversation → transcript | Task → reviewable artifacts (plans, walkthroughs, screenshots, browser recordings) |
| Parallelism | One thread (subagents internal) | First-class parallel agent manager |
| Verification | Agent runs tests/curl, you read output | Agent records proof (video, screenshots) |
| Context | Accumulated: skills, rules, MCPs, devin-kb | Fresh: rebuild via rules files |
| Reach | Whole machine + Tailscale + MCP (postgres, HA, yomi, github) | Same terminal reach + MCP support |
| Billing | Cognition plan | Google quota tiers |

Practical: flows converge for "fix bug, restart service" tasks. Antigravity wins on parallel agents + recorded proof; Devin wins on cross-machine/infra context already built up.

## How to run a proper eval

Methodology from benchmark research (Terminal-Bench, SWE-bench, KDD scaffold-effect paper):

1. **Compare harness–model pairs, not tool names.** Harness choice alone: up to 40x token difference per solved task, 0–8pp pass-rate difference. Record which model each tool used.
2. **Frozen environment.** Same repo snapshot per run — use `git worktree`. Identical prompt text, no mid-run hints (or count interventions).
3. **Multiple attempts.** 3 runs/task, report pass@1 with paired bootstrap CI. Single runs are noise.
4. **Verifiable grading.** Write acceptance tests first; tests pass/fail > vibe review. LLM-judge only for what tests can't cover.
5. **Measure beyond pass rate:** USD cost, tokens, wall-clock, human interventions, unrelated-test breakage.
6. **Avoid contamination.** SWE-bench tasks are in training data — use recent GitHub issues or private-repo tasks.

## Repos

Eval/benchmark frameworks:

- `aws-samples/sample-agent-cost-bench` — cost+quality+latency across Antigravity, Devin, Claude Code, Codex, Copilot, Cursor, Kiro, OpenCode. Bring your own repo + tests.
- `ttxs69/coding-agent-eval` — reproducible CLI-agent benchmark, live leaderboard
- `minghinmatthewlam/openbench` — harness-level comparison holding model constant
- `he-yufeng/CodeJoust` — same task → parallel worktrees → auto-grade
- `linny006/agent-eval-harness` — live real GitHub issues, auto-updated leaderboard
- Terminal-Bench (tbench.ai) — standard hard benchmark; Harbor runs Claude Code, OpenHands, Codex CLI
- `murphye/ai-coding-tools-comparison-guide` — side-by-side facts guide (Mar 2026)

Open-source agentic IDEs/tools (approx stars, Oct 2026):

| Tool | Stars | Shape | Notes |
|---|---|---|---|
| sst/opencode | ~198k | terminal + desktop | Most active OSS agent |
| OpenHands | ~84k | agent platform, CLI/SDK | formerly OpenDevin |
| zed | ~75k | editor (Rust) | built-in agent panel |
| cline | ~70k | VS Code/JetBrains ext | Plan/Act modes, approvals |
| goose (Block) | ~53k | CLI + desktop | automation |
| aider | ~48k | terminal | git-native pair programming |
| continue | ~35k | IDE extension | final release, unmaintained |
| tabby | ~34k | self-hosted server | team completions |
| Kilo Code | ~28k | VS Code/JB/CLI | Cline-descendant, 500+ models |
| void | ~29k | VS Code fork | archived Jun 2026 |
| Roo Code | ~24k | VS Code ext | archived May 2026 |
| bolt.diy | ~20k | browser app-gen | |
| Stagewise | ~7k | agentic IDE + previews | AGPL |
| awesome-Antigravity (ZhangYu-zjut) | — | guide | Antigravity tips/rate limits |

Note: Void and Roo Code archived mid-2026 — space moves fast, check activity before adopting.

## Eval plan (decided 2026-10-23)

Matrix: opencode, OpenHands, Devin, Antigravity — all four.

- **Axis A (harness-isolated):** opencode vs OpenHands on one pinned API model (Claude or Gemini via key). Devin (SWE-2) and Antigravity (Gemini) can't share a model, so they only appear in Axis B.
- **Axis B (product-level):** all four on best config.

### Plain version

A driving test for AI coders: same exam, same rules, machines grade it. Rewind a repo to before a known bug fix, tell each tool "fix this bug," run the test the original fixer wrote. Pass = tool did the job. Same brain (model) plugged into opencode + OpenHands isolates the tool body; Devin/Antigravity measured as whole products.

### Pilot status (2026-10-23)

- Built at `~/evals/` — tasks in `~/evals/tasks/`, config `config.pilot.yaml`, cost-bench at `~/evals/repos/sample-agent-cost-bench`
- Key discovery: `agent-cost-bench` supports `runner: local` score scripts — better than docker for repo tasks (repo lands at workspace ROOT, not src/)
- Held-out tests verified discriminating both directions (fail at parent / pass at fix) for T1, M1, M2
- **Both paid lanes capped**: OpenRouter key $10/wk limit hit; Gemini project monthly spend cap hit. Pivoted to free lane: `bench` model group on LiteLLM proxy (`100.102.134.91:4000`) → `gemini-3.5-flash-lite`
- opencode provider: custom `litellm` provider in `~/.config/opencode/opencode.json` (openai-compatible + `{env:LITELLM_KEY}`)
- openhands: needs `LLM_MODEL=litellm_proxy/bench` — the unrecognized alias name disables prompt caching (Gemini free tier rejects CachedContent → 429). `openai/` route makes it echo system prompt instead of tool-calling.
- First results (flash-lite, T1): opencode 6/7 tests w/ `covers` near-miss (real fix `covered_by`); openhands 0 edits (model too weak for its agent protocol)
- flash-lite verdict: intern-grade — finds the file, plausible wrong fixes, MUST be behind test gates
- **Ops-class results (O1–O4, 2026-10-23) — the important one:** both tools passed 3/4 ops chores at score 1.0 (endpoint probing→JSON, YAML config edit, systemctl state report). flash-lite+opencode did them in **12–16s each**. o3 log-triage: opencode 0.75 (prompt ambiguity — wrote `[dispatch-runner]` incl. brackets; prompt fixed), openhands timed out at 600s on the 11KB embedded-log prompt.
- Ops verdict: **the free lane already carries chore-class work** — curl/systemctl/YAML chores pass the gate at $0. The gap is long-horizon code, not chores. OpenHands also scored 1.0 on 3 ops tasks — its protocol failure is specific to sustained code tasks, not chores.
- Blocked: `devin auth login`, `agy` install+login (both manual); OR reset 2026-10-26
- Held-out-test bias: injected Go tests reference fix-commit symbols (e.g. `rc.connected`) — compile fail = 0; may undercount behaviorally-correct divergent fixes
- Antigravity deferred — `agy` needs manual install + Google login

### Steps

0. **Prereqs** — DONE: opencode 1.19.4 (`~/.local/bin/opencode` symlink → npm prefix `~/.local/node`), openhands CLI (uv tool), devin CLI 3000.11.92 (headless runner via cost-bench `devin_export`), `aws-samples/sample-agent-cost-bench` cloned to `~/evals/repos/`. All task repos public.
1. **Task corpus via git archaeology** — mine repo history for commits that fixed a bug AND added a test: reset to parent, prompt = issue description, verifier = the fix's test (held out: workspace at parent commit lacks it, verifier injects it). Pilot tasks:
   - T1 terrology `f8a5d9c` — elevated-geom predicate fix + output-quality tests (easy)
   - T2 terrology `efb9996` — double water recession fix + tests (medium)
   - M1 mddb `c0850f0` — follower health reflects replication state + `TestHandleReplicationStatus_FollowerHealthyReflectsReplication` (medium, Go)
   - M4 mddb `bfb3b7c` — stream binlog Rotate w/o buffering (hard, custom verifier)
2. **Smoke test** — 2 tasks × each tool through cost-bench; verify worktree isolation, token/cost capture, verifier grading. Fallback: ~100-line bash worktree runner.
3. **Full runs** — 10 tasks × 3 attempts × 4 cells ≈ 120 runs. Log: pass/fail, wall-clock, tokens, USD, interventions, unrelated-test breakage.
4. **Report** — results.csv + summary committed back into this file/dir for cross-tool transfer.

### Later corpus candidates

- M2 mddb `497b982` open-only integrity proof + test
- M3 mddb `dc88ede` + `ad7708a` snapshot-below-oldest fix + test commit
- T3 terrology `ae92c85` building clipping fix
- T4 terrology `be9bfa9` `--waterways` feature
- M5 mddb `60ac37c` MDDB_FREELIST_SYNC default-on feature
- S1 service task — ans-fleet (ansible-lint verify) or ada-pi
