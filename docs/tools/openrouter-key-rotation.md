# OpenRouter key rotation (mddb embed chain)

2026-11-12 outage lesson: `~/.config/secrets/mddb-gemini.env` on **idc03**
is the single rotation point for the embed chain — both
`gemini-ollama-proxy` (:11435) and `litellm` (:4000) read
`OPENROUTER_API_KEY` from it. The same key is also deployed in
`ada-chaba.env`, `ada-dev.env`, `ada-pi-pwa.env` (shared key, same budget).

## Rotate

1. Create the new key in the OpenRouter dashboard; save it to
   `~/.config/secrets/or-tony-mddb.txt` (single line, mode 600).
2. Replace `OPENROUTER_API_KEY=` in all four files:
   `mddb-gemini.env` (active line), `ada-chaba.env`, `ada-dev.env`,
   `ada-pi-pwa.env`.
3. `systemctl --user restart gemini-ollama-proxy litellm ada-chaba
   ada-dev ada-pi-pwa` (scenario timers pick it up on next run).
4. Verify: `curl :11435/api/embed` returns 768 dims; mddb
   `vector-search` embeds without "all same-space providers down";
   `mddb-embed-probe.service` → `Result=success`.

## Watchdog

`scripts/or-key-watch.py` (deployed on idc03 `~/bin/`) scans
`~/.config/secrets/*.{env,txt}` for `sk-or-*` keys (deduped, skips
comments), queries OR `/api/v1/key`, exits 1 if any key expires <14d
or `limit_remaining` <$0.10. `or-key-watch.timer` runs it Mon 08:00;
a nonzero exit is auto-carded by timer-sentinel. Tune via
`OR_WARN_DAYS` / `OR_WARN_REMAINING_USD`.

## Chain map

mddb → gemini-ollama-proxy → OpenRouter (direct, `OPENROUTER_API_KEY`)
→ direct Gemini (`GEMINI_API_KEY`, free tier) → Ollama (different
vector space — fail-closed, never silently writes cross-space vectors).
litellm serves `gemini-embedding-2` (paid key, works independently)
and `or-gemini-embedding-2` (same OR key). Vectors: `gemini-embedding-2`,
768 dims — a same-space provider must match or the index rebuilds.
