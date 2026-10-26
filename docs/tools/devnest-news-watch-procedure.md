---
title: DevNest news watch procedure
description: Standard procedure for tracking meaningful DevNest advancement in news, reports, and Education
tags: [devnest, news, reports, education, continuous-improvement]
category: operations
status: active
---

# DevNest News Watch Procedure

DevNest advancement should be visible without turning every routine queue run
into a news item. The news watch is a lightweight evidence pass over the same
artifacts used by QA, QC, audit, and benchmark work.

## Sources

Scan the delta since the previous watch:

- Kanban cards and comms: new capability, verified result, failure, or decision.
- Git commits and merged branches: implementation milestones and fixes.
- Nest pack artifacts: reports, metrics, images, audio, and verifier results.
- JEV confusion matrices and lane outcomes.
- OpenCode/Devin replay results, token usage, cost, and intervention records.
- Host assessments, Education updates, and audit reports.

## Publish triggers

Create or update a news item only when at least one trigger is true:

1. **First production milestone** — a route, skill, executor, or UI completes a
   real job end-to-end.
2. **Verified benchmark delta** — meaningful before/after result with a gate,
   sample size, and reproducible artifact.
3. **Real savings** — measured cost/token/human-time reduction against a
   comparable baseline; never infer savings from a free model alone.
4. **New capability** — a surface or lane becomes usable by Tony.
5. **Important failure/root cause** — a failure changes routing, safety, or
   architecture.
6. **Decision** — a researched choice changes the workforce design.

Routine successful runs, repeated heartbeats, and unchanged status do not need
news coverage.

## News record

Every item must include:

```text
date
headline
what changed
why it matters
before/after or baseline
evidence links (card, commit, artifact, report)
confidence
next step
```

Use confidence labels:

- `verified` — independent gate/artifact confirms it.
- `measured` — benchmark result, but limited sample or pending replication.
- `observed` — useful signal, not yet a conclusion.

## Integrate, do not fork

Before creating a new report:

1. Search existing news/report pages for the same story.
2. Update the existing parent when this is a chronological development.
3. Create a new parent only for a different scope, audience, or decision.
4. Link the news item to the detailed Education lesson.
5. Keep SSOT concise: decision, verdict, current state, and lesson/report link.

The existing `news-digest.py` clustering process should consolidate related
source items. DevNest news is a source stream, not a competing report system.

## Cadence

- **Per job:** land evidence and card comms; do not publish news automatically
  unless a trigger is clearly met.
- **Daily:** scan DevNest/CI deltas and queue candidate news notes.
- **Weekly:** review candidates, merge related stories, and publish verified
  milestones.
- **Monthly:** publish the savings/lane scorecard after enough matched jobs
  exist; include failures and confidence, not only wins.

## Current examples

- T4 embedding benchmark: publishable measured milestone.
- Gaussian v2 renderer: publishable verified improvement over v1.
- JEV first live merged job: publishable production milestone.
- Host assessment skill batch: publishable capability milestone.
- OpenCode model-chain probe: publishable failure/root-cause note until
  closeout passes; do not call it production savings before then.
