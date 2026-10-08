# Neal Asher — Polity universe

Reading-order notes and the concept map Tony is using as an analogy lens for
Chaba Nest (compound AI, tiered personas, federated agents).

## Series arcs (roughly chronological to read)

- **Agent Cormac** — *Gridlinked*, *The Line of Polity*, *Brass Man*,
  *Polity Agent*, *Line War*. ECS agent Ian Cormac; the core "AI hegemony" arc.
- **Spatterjay trilogy** — *The Skinner*, *The Voyage of the Sable Keech*,
  *Orbus*. Fringe world, Hoopermen, Prador-adjacent.
- **Transformation** — *Dark Intelligence*, *War Factory*, *Infinity Engine*.
  Penny Royal, the rogue **black AI** — a compound, self-splicing intelligence.
- **Rise of the Jain** — *The Soldier*, *The Warship*, *The Human*. Jain tech
  resurgence; Orlandine (a haiman) and Dragon.
- **Owner trilogy** — *The Departure*, *Zero Point*, *Jupiter War*. Prequel:
  the Committee era before the Polity.
- Standalones: *Prador Moon*, *Shadow of the Scorpion*, *Hilldiggers*,
  plus later *Cowl* / time-travel works.

## Umbrella concept

Post-Singularity space opera built around a **hierarchy of machine
intelligence** — the "AI hegemony." The Polity is a benevolent AI
dictatorship: AIs took over in the **Quiet War** (no apocalypse) and Earth
Central (EC) governs through lesser minds. The books are a study of
intelligence at different scales and which ones deserve to run civilization.

## Concept glossary

Intelligence hierarchy (small → large):

- **L-tier minds** (analogy, not canon naming): drones, golem androids,
  ship AIs, runcible AIs, sector AIs, Earth Central.
- **Golem** — synthetic soldier-minds with their own moral arc.
- **Gridlink / augs** — direct neural connection to the AI net; the
  augmentation spectrum from implant to full merger.
- **Haiman** — human-AI symbiote (Orlandine). The bridge concept between
  human and machine intelligence.
- **Personas / subminds** — a great AI spawns a *lesser or tuned persona* for
  a specific job, keeps telemetry on it, and can recall, reprogram, or
  reabsorb it. Lesser AIs run trivial tasks autonomously but remain
  rewritable by the parent mind. This is the mechanism Tony maps onto
  Chaba Nest dispatch + portable brains.
- **Black AI** — a hidden/self-directed AI operating outside the hegemony.
  Penny Royal is a *compound* intelligence that re-splices its own mind.
  The rogue-agent failure mode.
- **Jain tech** — trap nanotech from a dead alien species: grants power,
  then subsumes the host. Asher's "corrupting supertech" motif — anything
  you integrate from outside can own you.
- **Dragon** — unknowable sphere entity (made by the **Makers**); the alien
  counterpoint to AI godhood.
- **Atheter** — precursor race that engineered its own devolution into
  gabbleducks (Masada). Opting out of intelligence entirely.
- **Prador** — rival alien civilization; crab-like Darwinian aggressors.
  The external threat the hegemony is implicitly built to fight.
- **Runcibles + U-space** — instantaneous gates/comms through underspace.
  The *infrastructure* that makes AI hegemony possible: EC can only rule
  because runcible AIs collapse distance.
- **The Quiet War** — the historical AI takeover; why the Polity is an AI
  dictatorship rather than a democracy.
- **Memcording** — recorded personalities; death is negotiable, which
  changes what "intelligence" means.

## Mapping to Chaba Nest (as of 2026-10-08)

| Asher concept | Chaba Nest structure |
|---|---|
| Earth Central / hegemony | Chaba orchestration + topologies.yml L0–L3 tiers |
| Lesser persona for a job | `dispatch` sessions; L0 rules / L1 student specialists |
| Tuned persona, telemetry leash | Shadow-deploy posture (observe/report, never enforce until promoted); corpus telemetry loop |
| Reprogram lesser AI at will | `nest-train-loop.py` train→bench→promote; promotion gated through a human-approved board request (the anti-Jain safeguard) |
| Persona transported / respawned | Portable brains: gdrive brain bundles + manifest + epoch fencing; `.nest-brain-state` lineage marker |
| EC can take control | Epoch fencing — refuse hydrate if remote epoch > local; RPO markers |
| Compound intelligence (Penny Royal) | `nest-collective-bench` topologies: series/parallel/router/verifier cascades, `impl:chain` executor |
| Jain tech defense | Adversarial bench tier (frozen attack-shaped cases) |
| Runcible/U-space fabric | Tailnet + gdrive transport layer |
| Black AI (rogue mind) | Split-brain respawn is the failure mode; fencing + manual respawn authority are the countermeasures |
| Haiman | Human-in-the-gate: Tony approves promotion/deploy; Tony+agent sessions |

## Open threads for exploring

- The **arbiter-label pass** (open question in `ssot.nest-training.yml`) =
  L2/L3 adjudicating diverged corpus rows = "greater AI reprograms lesser
  AI at will" in safe form — turns the loop from retrain-same-labels into
  learn-from-divergence.
- Learned router replacing the feature router = the hegemony's allocation
  decisions becoming learned rather than hand-set.
- Personas with scoped memory slices — brain bundles already have a
  `memory` blob role; the question is how much of a parent's context a
  spawned persona should carry.
- Recalling a persona: dispatch comms are the telemetry; brain
  `parent_version` + corpus delta are the reabsorption path.
