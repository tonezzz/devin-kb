---
title: DevNest continuous improvement standard
description: QA, QC, audit, benchmark, and feedback loop for delegated DevNest work
tags: [devnest, qa, qc, audit, ci, benchmark, continuous-improvement]
category: operations
status: active
---

# DevNest Continuous Improvement Standard

DevNest is not a second untracked automation layer. Every delegated job must
advance through the same quality loop as the rest of Chaba.

## Job lifecycle

1. **Discover** — identify a real repeated job or a measured failure.
2. **Card** — record the goal, `target_host`, owner, risk, and expected artifact.
3. **Specify the gate** — define a deterministic done-condition before routing.
4. **Route** — JEV chooses `codemod`, `free_lane`, `paid_frontier`, `devin`, or
   `manual`; unknown cases fall back to the safer lane.
5. **Isolate** — use a worktree, scratch directory, controlled host, or pack.
6. **Execute** — run the cheapest eligible executor.
7. **Verify independently** — use held-out tests, schema checks, behavior checks,
   artifact checks, or host evidence. Never use the agent's own claim as proof.
8. **Review and merge** — branch work must pass the normal closeout gate; failed
   gates stay in review.
9. **Land artifacts** — commit, report, lesson, card comms, or Drive artifact.
10. **Measure** — record time, tokens/cost, interventions, escalations, and gate
    result.
11. **Feed back** — add misroutes, failures, and reusable fixes to JEV labels,
    skill rules, codemods, verifiers, or Education.

## Four quality layers

| Layer | Question | Typical output |
| --- | --- | --- |
| QA | Did we specify the right job and acceptance gate? | card + task fixture |
| QC | Did the produced artifact meet the gate? | verifier result |
| Audit | Did the process land durable evidence and obey policy? | audit report/card |
| Benchmark | Is this lane cheaper, faster, or safer than the baseline? | trend report |

## Safety gates

- `target_host` is mandatory whenever the job inspects a different machine.
- Read-only assessment is the default; remediation is a separate approved card.
- Destructive operations, credentials, partition changes, deployments, and
  account actions never auto-route without a human gate.
- A stale heartbeat, stale claim, missing artifact, or unknown lane causes a
  safe defer rather than an opportunistic retry.
- A baseline test failure is only non-blocking when the identical failure is
  reproduced on the base revision and the changed surface is not implicated.

## Cadence

- **Per job:** verifier, artifact, card comms, and execution metrics.
- **Daily:** host assessment, queue/claim freshness, and Education/report refresh.
- **Weekly:** JEV confusion matrix, replay sample, stale-claim review, and
  free-lane savings report.
- **Monthly:** compare DevNest against Devin baselines; promote, tune, or retire
  lanes based on passed-gate cost rather than raw model price.

## Metrics

The primary economic metric is:

```text
cost per independently verified successful job
```

Also retain wall time, token/API cost, human intervention minutes, retries,
target-host correctness, unrelated-test breakage, merge success, and escalation
rate. No savings claim is valid without a passed gate and a durable artifact.

## Current DevNest examples

- Host assessment: deterministic SSH evidence -> JSON verifier -> Education.
- T4 embedding/Gaussian packs: GPU artifact -> report -> no production mutation.
- JEV lane routing: classifier -> executor -> verifier -> merge.
- OpenCode lane: model selection and execution work; branch closeout remains a
  gate until the verified worktree/merge path is stable.
- Devin replay benchmark: historical sessions become frozen tasks with held-out
  verifiers.
