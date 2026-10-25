# Inference provider market — living research

Tracks hosted LLM inference options vs our lanes (see `ai-workforce-eval.md` for
the surfaces × brains × task-classes frame). Iterated — each pass adds providers,
refreshes prices, and logs what changed in the Iteration log at the bottom.

**The one cost rule for our workloads:** agent sessions are prefill-heavy —
~40K input tokens re-sent per turn vs ~600 output. So the ranking metric is
**cached-input price × cache-hit rate**, not headline $/Mtok. With ~80% cache
hits, a 30-turn session costs **cents, not dollars** on the cheap tier —
and ~7× more on providers with no published cache price.

## Market map (as of 2026-10)

| Segment | Players | What they're for |
|---|---|---|
| Frontier labs | OpenAI, Anthropic, Google, xAI, Mistral | hard tasks, review, single-source models |
| Open-model speed shops | Groq, Cerebras, Fireworks, Together, Baseten, DeepInfra | fast/cheap open weights; list prices converged — differentiators are TTFT, throughput, catalog |
| Aggregators | OpenRouter (+5.5% on credits), Vercel AI Gateway (BYOK) | one key → many providers; `or-*` lane |
| GPU-seconds | Modal, Lambda, RunPod | self-host weight; no token pricing |
| Free tiers | see table below | the rainy-day lane |
| Local | Ollama (idc02 qwen, omen), Colab worker | zero-cost, weak brains |

## Free tiers — the current rainy-day inventory (checked 2026-10-25)

| Provider | Free models worth noting | Limits | Data training | Notes for us |
|---|---|---|---|---|
| **Google AI Studio** | Gemini 3.5/3.1 flash-lite (our `bench`), 2.5 Pro/Flash, flash, Gemma, TTS | per-model daily quota (account-age scaled), resets midnight PT | **yes** on free tier | current workhorse — keep; flash-lite remains the best free all-rounder |
| **Groq** | **gpt-oss-120b, gpt-oss-20b, qwen3.8-27b**, Whisper large-v3 | ~30 RPM / 1K RPD / 200K TPD per model | no (opt-out; ZDR available) | **big find** — 120B param model free + 1000 tok/s; tool-calling viable. Candidate to replace local qwen3:8b as free code brain |
| **OpenRouter `:free`** | rotating list (~20 models; gemma-4, nemotron, dots…) | 20 RPM, 50/day — **1,000/day after $10 credit purchase** | depends on routed provider; per-model opt-out | $10 once → 20× daily cap; worth doing |
| **Mistral** | Codestral, Small/Large (Experiment tier) | ~1B tokens/mo, rate-limited | **yes** on Experiment | codestral = free code brain candidate |
| **Cloudflare Workers AI** | Llama 4 Scout, gpt-oss-120b/20b, Qwen3, Whisper, BGE embed | 10K Neurons/day | unstated | embed+whisper+LLM in one key |
| **NVIDIA NIM** | nemotron-3-nano, llama variants | ~1K req/day per model | no | nemotron-3-nano-omni reasoning free on OR too |
| **Cerebras** | gpt-oss-120b, qwen3.8-27b | $5 trial credits, 30d expiry, card req | no | 2000+ tok/s — speed trials, not a permanent tier |
| **GitHub Models** | GPT-4o, Claude, Llama, Phi | 15 RPM, 150–1000/day | no | **frontier models free** — capped hard but real |
| **OpenCode Zen** | rotating promo list (Big Pickle, MiMo, Ling…) | promo-window only | varies | free models usable **directly in opencode** — zero-config eval lane |
| **SambaNova** | Llama 405B-class | 20 RPM/20 RPD/200K TPD | no | small daily cap |

## Cheap coding-agent brains (the class our evals actually need)

List prices Oct 2026, $/1M in/out. All support tool calling + ~1M context.

| Model | In | Cached in | Out | ~Cost per large run¹ | Fit |
|---|---|---|---|---|---|
| **DeepSeek V4 Flash** | $0.08–0.30² | $0.003–0.006 | $0.60–1.20 | ~$0.05–0.11 | cheapest credible code brain; off-peak rates |
| **GLM-5.3 Flash** | $0.15 | $0.03 | $0.50 | ~$0.14 | strong cheap agent; always-on reasoning counts as output |
| **Qwen3.8 Flash** | $0.15 | $0.016 | $0.47 | ~$0.30 | same family as local qwen3 — easy compare |
| **MiniMax M3.1 Flash** | $0.15 | — | $0.60 | — | new, agentic-tuned |
| **MiMo V2.6 Flash** | $0.14 | — | $0.28 | ~$0.60 | cheapest output price here |
| **GLM-5.2/5.3** | $1.25–1.40 | — | $4.00–4.40 | ~$2.05 | mid-tier, served by everyone ($ spread ≤5%) |
| **Kimi K3 / K2.7** | $0.67–3.00 | $0.30 | $3.40–15.00 | ~$1.35–5.80 | top open-weight coder; pay for consistency |

¹ 1M input + 200K output (large refactor / long session) where published.
² DeepSeek official has peak/off-peak rates — off-peak roughly halves cost.

## Frontier (paid, single-source)

| Model | In / 1M | Out / 1M | Note |
|---|---|---|---|
| GPT-5.2 | $1.75 | $14.00 | GPT-5-mini cheap SKU: $0.25/$2.00 |
| Claude Sonnet 5.5 | $2.00 | $10.00 | Haiku 5.5: $0.10/$0.50, 1M ctx |
| Gemini 4 Argon | $2.00 | $10.00 | batch halves it; not in free tier |
| Grok-4.7 | $2.00 | $6.00 | |

## How it maps to our lanes

- **`bench` (chores/evals):** gemini-3.5-flash-lite free tier stays the default.
- **Free code brain upgrade:** local `qwen3:8b` → **Groq `gpt-oss-120b` or `qwen3.8-27b`** (free, real tool-calling, ~20× faster than CPU ollama). This is the single biggest free upgrade available right now.
- **OpenRouter cap:** a one-time $10 credit turns `:free` models from 50→1000 req/day — cheap insurance for the `or-*` lane.
- **Cheap paid code brain:** DeepSeek V4 Flash (~$0.05–0.11/session) or GLM-5.3 Flash (~$0.14) — under $20/mo even at daily-eval volume.
- **Voice/latency (ada):** Groq/Cerebras are the TTFT outliers (1–2k tok/s) — relevant when a voice turn needs a brain, not for batch evals.
- **Eval discipline:** the harness measures real outcome per lane — new providers go in as LiteLLM model groups, then a `config.<name>.yaml` + `agent-cost-bench cli-compare run` tells us if they actually finish tasks. Headline $/Mtok is the hypothesis; the eval score is the verdict.

## Experiments queued / next iteration

- [ ] Add `groq-free` model group (gpt-oss-120b + qwen3.8-27b) to LiteLLM → run `config.ops.yaml` vs `bench` baseline
- [ ] OpenCode Zen free models as a zero-config `config.zen.yaml` runner
- [ ] $10 OpenRouter credit → unlock 1K/day `:free` + paid pass-through for DeepSeek V4 Flash bench
- [ ] Mistral Experiment tier key → Codestral eval leg
- [ ] Compare Groq TTFT for ada voice aux vs current path
- [ ] Check gemma3-tools community template vs qwen3 on colab worker

## Sources & method

- c17.io/compare/llm-apis (normalized prices, 2026-10-18), metergraph.dev buying-inference, continuumcode.ai providers guide, freeintelligence.ai free-tier tracker, openrouter free-API roundup, runaii.cloud coding-agent pricing, aiapi-pro chinese-LLM cost table, tokens.bd cheap-coding-models.
- Prices are list rates; same weights can vary 2–14× across providers — check live pages before committing spend.

## Iteration log

- **2026-10-25 — iter 1:** initial landscape. Finds: Groq free 120B (biggest free-brain upgrade), OpenRouter $10→1K/day trick, cache-price as the real agent-cost axis, OpenCode Zen free lane, GitHub Models free frontier.
