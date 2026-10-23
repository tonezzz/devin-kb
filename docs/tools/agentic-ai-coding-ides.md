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

### Steps

0. **Prereqs** — install opencode (npm/brew), OpenHands CLI (uv), Antigravity CLI; clone `aws-samples/sample-agent-cost-bench` to `~/evals/`; API key for pinned model. Antigravity free-tier weekly quota → spread its ~30 runs over days. Devin has no headless mode → run per-task in fresh sessions, semi-manual.
1. **Task corpus via git archaeology** — mine repo history for commits that fixed a bug AND added a test: reset to parent, prompt = issue description, verifier = the fix's test. Pre-verified, real tasks, no extra test-writing. ~10-12 tasks across terrology + chaba + one service repo. Mix: 3 bugfix / 3 feature / 2 refactor / 2 test-writing / 1-2 service-touching (Tailscale). Pilot with 4 tasks before scaling.
2. **Smoke test** — 2 tasks × each tool through cost-bench; verify worktree isolation, token/cost capture, verifier grading. Fallback: ~100-line bash worktree runner.
3. **Full runs** — 10 tasks × 3 attempts × 4 cells ≈ 120 runs. Log: pass/fail, wall-clock, tokens, USD, interventions, unrelated-test breakage.
4. **Report** — results.csv + summary committed back into this file/dir for cross-tool transfer.
