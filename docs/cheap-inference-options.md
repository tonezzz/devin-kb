# Cheap On-Demand Inference Options

Surveyed Sept 2026. Goal: pay-per-use inference for development — no always-on servers.
Prices are snapshots; re-check vendor pricing pages before committing.

## Tier 0 — Free ($0, good enough for a dev loop)

| Provider | What you get | Catch |
|---|---|---|
| Groq free tier | ~30 RPM / 1K req/day, 300–800 tok/s on open models (gpt-oss-120b, Qwen, Llama) | Rate limits; narrow model list |
| Google AI Studio (Gemini) | ~15 RPM / 1K req/day, 250K TPM on Flash-Lite | RPM caps; limits only visible in AI Studio |
| Cloudflare Workers AI | 10K neurons/day free (~few hundred chat turns), 50+ models at the edge | Workers Paid ($5/mo min) past daily cap |
| Cerebras | ~2,000 tok/s, fastest public inference | No longer free — $5 credit trial only |

## Tier 1 — Per-token APIs (no infra; cheapest for standard open models)

| Provider | Price signal | Notes |
|---|---|---|
| DeepInfra | Cheapest of the group (e.g. gpt-oss-120b ~$0.037/$0.17 per M tok) | What OpenRouter often routes to |
| Novita / Hyperbolic / SiliconFlow | Close behind DeepInfra | Broad catalogs, less mature tooling |
| Groq / Together / Fireworks | ~$0.15/$0.60 per M tok on small models | Speed (Groq) or production features (Fireworks) |
| OpenRouter | Pass-through pricing + 5.5% credit fee; has free models | One key → 400+ models / 60 providers; best dev UX |

## Tier 2 — Serverless GPU, per-second (your own model, scale-to-zero)

| Provider | H100 rate | Billing | Cold start | Best for |
|---|---|---|---|---|
| Modal | ~$3.95/hr | Per-sec, no minimum | ~2–4s | Best Python DX — model is a decorated function |
| RunPod Serverless | ~$4.55/hr (RTX 5090 ~$1.58/hr) | Per-sec, rounded up | ~5–8s | Cheapest control, consumer GPUs for small models |
| Beam | ~$3.20/hr | Per-sec | ~2s warm pools | When cold-start latency is the KPI |
| Replicate | ~$5.49/hr | Per-sec | Seconds | Push a model, get an API |
| Baseten | ~$6.50/hr | Per-minute | ~0 if warm replicas | Most managed; pricey for spiky dev use |

Rule of thumb: serverless beats dedicated GPU below ~2/3 utilization — almost any dev/bursty workload.

## Tier 3 — AWS-native

- **Lambda + GGUF from S3** (memfd + llama-cpp-python + SnapStart): only for CPU-sized models
  (~≤1.5B–7B quantized), spiky traffic. ~30 tok/s ceiling, 10 GB / 15 min limits.
  Ref: AWS Compute Blog, "Deploying AI models for inference with AWS Lambda using zip packaging" (Oct 2025).
- **Bedrock on-demand**: per-token, zero infra — the AWS answer if already in that ecosystem.

## Tier 4 — Local, $0 marginal

- **tony-omen** (GTX 1650 4GB + 32GB RAM, on Tailscale): Ollama/llama.cpp runs 3–8B Q4 models
  at ~5–15 tok/s. Fine for dev/test loops; too slow for user-facing.
- **tony-dell** (8GB RAM, no usable GPU): skip — barely fits a 3B model on CPU.

## Recommendation for our development

1. Day-to-day dev/prototyping → OpenRouter (one key, swap models, free models for tests)
   + Groq/Google free tiers as fallbacks.
2. Production-ish open-model serving → DeepInfra direct (cheapest).
3. Custom/non-LLM models (fine-tunes, embeddings, classifiers) → Modal for DX,
   RunPod Serverless if cost-sensitive.
4. Lambda+GGUF → only when a model must live inside AWS next to other infra.

## Ada (ada-pi) current spend model

- Dominant cost: Gemini Live audio sessions (~$0.5–0.9/hr at Flash-Live audio rates).
- `ADA_VIDEO_MODE=continuous` adds ~$0.28/hr vs ~$0.02–0.05/hr for `activity` mode — keep activity.
- Habit confirmations (flash-lite single images): negligible (<$1/mo).
- If `GEMINI_API_KEY` is a free-tier AI Studio key, usage under daily limits is $0.
- Token usage is ledgered per-source in `backend/usage_tracker.py` and persisted to
  `data/usage.jsonl` (env `ADA_USAGE_LOG`; `off` disables). Ada answers usage/cost
  questions via the `ada_usage_summary` tool (source filter + reset); modality split,
  cached/tool-use tokens, turn counts, per-day buckets, rough USD estimate.
