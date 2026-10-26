# MCP fleet audit — 2026-10-26

Live `mcp_list_tools` probe of every server in `~/.config/devin/mcp_config.json`
(19 entries) plus SSOT-only servers from `ssot.mcp.yml`. Done under AUD-0886.

## Liveness verdict

| Server | Live? | Tools | Verdict |
|---|---|---|---|
| mcp-debug | yes | ~13 | **keep** — flagship: compact multi-host debug + measured token-savings machinery (`mcp_savings`, `mcp_stats`, `mcp_vet`). |
| mcp-health | yes | ~25 | **keep** — deep SSOT health layer, alerts, auto-recovery, PG history. Boundary vs mcp-debug documented (service health vs host debug). |
| mddb | yes | 6 | **keep** — but SSOT stale: live config uses idc03 `http://100.102.134.91:9000/mcp` + X-API-Key; SSOT still describes tony-dell container + stdio bridge. |
| mcp-weaviate | yes | 2 | **keep** — semantic search over chaba KB/SSOT. Overlaps mddb `semantic_search`; rule: weaviate = chaba repo corpus, mddb = general doc store / ada banks. |
| mcp-colab | yes | 5 | **keep** — the local-gpu-packs lane control plane. **Missing from `ssot.mcp.yml`** entirely — drift fix needed. |
| mcp-gpu | yes | 4 | **keep** — GPU status + llama hold/resume + imagen generate (image-gen lane). |
| playlive | yes | ~30 | **keep** — Chrome/CDP + Playwright. Heaviest schema in the fleet (~600 lines); allowlist candidate. |
| github | yes | ~40 | **keep** — already behind `mcp-allowlist.py`. |
| postgres | yes | 6 | **keep** — read-only set via allowlist (query/schema/table ops only). |
| yomi | yes | ~10 | **keep** — LINE integration, richer than SSOT shows (unread digest, insight, send_message). |
| docs-trade | yes | 3 | **keep** — cheap, trade-scoped. |
| alphavantage | yes | ~40+ | **gate it** — **~5.6k lines of schema** (~15k tokens) injected into every session for a rarely-used tool. Apply `mcp-allowlist.py` to ~6 core fns, or move to a per-session trade profile. |
| mcp-llama | yes | 5 | **retire/repoint** — `chat`/`complete`/`tokenize`/`models`/`status` against omen's llama-server, which is down for reboot-prep and is superseded by the LiteLLM gateway (central routing, fallbacks, spend ledger). Function absorbed by LiteLLM + opencode lanes. |
| mcp-focus | yes | 2 | **verify usage** — focus routing largely moved to kanban/board-api; candidate for retire if the focus-inbox flow is now board-driven. Keep until last-use is checked. |
| home-assistant | **DEAD** | — | **repair** — port 9584 not listening on dell. Entire HA read/control surface dark. |
| michael-ha | **DEAD** | — | **repair** — port 19584 dead. |
| michael-dev | **DEAD** | — | **repair** — port 9585 dead. |
| workflows | **DEAD** | — | **repair-or-retire** — podman container not running; check whether YAML runbooks are still used vs board-api queue verbs. |
| docs | **DEAD** | — | **retire candidate** — chaba docs-mcp ssh wrapper fails; mddb + ssot-search already cover the corpus. |
| notebooklm | **DEAD** | — | **repair-or-retire** — `notebooklm-mcp.service` crash-looping (`activating start/start`) on dell. |
| google-home-lan | n/a | — | **not wired** — operational on mn01 but absent from devin `mcp_config.json`; add if local cast control wanted in sessions. |
| google-home | n/a | — | **blocked** — needs Google Home Premium Advanced subscription; keep documented, not configured. |
| icloud | n/a | — | **not wired to devin** — works on mn01 via ssh exec; add only if session-side mail/cal/contacts access is wanted. |
| playlive-macbook | n/a | — | retired 2026-10-11 (no macOS target). |

## Cross-cutting findings

1. **Schema weight is the silent token cost.** alphavantage (~5.6k lines), github (~1.2k+), playlive (~600), yomi, mcp-health — every session pays for all of them. The allowlist pattern already exists (`mcp-allowlist.py` for github/postgres/yomi); extending it to alphavantage + playlive is the cheapest token save available. The 2026-08-07 `mcp_filter_disabled` decision should be revisited — per-server allowlists proved stable.
2. **Five configured servers are dead.** HA bridges (3×, same root cause likely — the HA-MCP proxy on dell), workflows, docs, notebooklm. SSOT still marks all `operational`.
3. **mcp-llama is obsolete** — LiteLLM on idc03 now owns model routing (with Groq/Zen/Colab fallbacks + spend ledger). A direct llama-server MCP adds nothing and points at a host that's routinely down.
4. **Which tool belongs to which lane** — added to `ai-lane-delegation.md` §tool-surface.

## Action queue

- [ ] Repair HA-MCP bridges on dell (9584/9585/19584) — card if >15min
- [ ] `mcp-allowlist.py` for alphavantage (core 6 fns) + playlive (~10 core)
- [ ] Retire mcp-llama from `mcp_config.json` (or repoint LLAMA_URL to LiteLLM `/v1`)
- [ ] SSOT drift fixes: mddb transport+endpoint, add mcp-colab, mark dead servers `status: down-2026-10-26`
- [ ] Decide workflows/notebooklm/docs: repair or retire (usage evidence first)
- [ ] Check mcp-focus last-use vs board-api focus flow
