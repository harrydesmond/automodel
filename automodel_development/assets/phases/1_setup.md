---
name: setup
entry: No `CONTEXT.md` in the project root, or its status says Phase 1.
exit: RUN_PLAN.md approved (light: whole plan; heavy: part A); CONTEXT.md created.
description: First phase. Agree the goal, data, decision rule, external evidence, budget and execution path; record them in RUN_PLAN.md and get approval.
---

# Phase 1 — Setup

Reuse answers the user has already given (in this conversation, project instructions or memory) and mark them
[user chose] or [delegated]; ask only what is open. Ask related questions together, and follow up on any that come back
skipped or partly answered.

## 0. Feasibility and size
- Confirm language/runtime and libraries, and whether sub-agents can be spawned with file and shell access. If not,
  agents run sequentially in this session; record that. Heavy searches with detached workers: check the platform
  (bash ≥ 4, `pgrep`, `setsid`) and which permission settings the user will approve.
- Estimate (or ask) how long one evaluation (a fit plus scoring) takes and where it runs, and classify the search as
  light or heavy (`assets/resources.md` §1). Heavy: ask the user's limits on usage, wall time and compute, and read
  `assets/frameworks.md` for this framework's mechanics.

## 1. Goal and claims
Domain vocabulary (loss vs cost, features vs covariates…); what the model is for (input range, extrapolation,
derivatives, runtime vs interpretability); required properties (positivity, monotonicity, symmetries, physical limits);
what the final claims will cover. Check the project's `references/` folder.

## 2. Existing code and data
Review existing code with the user and decide what to reuse. Identify the data files, input and output variables,
cleaning needs, groups (subjects, sites, datasets) and every other dataset available (keep independent ones for
replication).

## 3. Objective
- **Training loss** and **reported metrics**; always include runtime and memory per evaluation.
- **Requirements**: decide for each whether it is a hard gate (candidates failing it are rejected), part of the score,
  or reported only.
- **Selection score**:
  - Not complexity-penalised (RMSE, log-loss, …): measured out of sample, on a validation set or by (grouped,
    stratified or time-ordered) cross-validation.
  - Complexity-penalised (an information criterion, MDL, …): an agreed, well-defined criterion may rank candidates on
    all the data; a validation split is not needed merely to compute it. Decide separately whether the goal is a
    descriptive comparison or predictive generalisation, and whether independent evidence is affordable. A penalty does
    not make the winner of an adaptive search reliable by itself.
  - Hybrid (held-out error plus a penalty): set the penalty against the noise of the held-out score.
- **Read back the operative rule** in one sentence — "Among candidates satisfying [hard requirements over their
  domain], rank by [score and direction]; [other checks] are reported only" — and show how one known reference is
  ranked or rejected under it. Changes to this rule later are protocol changes (new version, rescoring).

## 4. Splits and external evidence
- Create the data files the score needs, if any (`train.X`, `validation.X` or folds); guard against leakage (repeat
  measurements of one entity across splits, time-series autocorrelation, duplicates).
- Agree the external check for Phase 4: a held-out test set, replication on independent data, or out-of-range
  constraints. Constraints assess admissibility, not predictive accuracy. If none is affordable, the user may agree to
  "exploratory, no independent check"; record what the criterion does not pay for (the number of candidates tried).
- A reserved dataset is excluded from the agents' inputs and refused by the evaluator before any scoring, references
  included. Record earlier exposure (e.g. benchmarking references on it) and sibling runs sharing it, and state what
  may be refitted at the final check.

## 5. Optimization routine
Implement or confirm a parameter optimizer (prefer libraries), with seeds, restarts and a stop criterion.

## 6. Budget and checks
- Evaluation budget: light, one fit cap and one wall-time cap; heavy, screens and scored fits per attempt plus
  run-wide fit, wall-time and compute caps. An attempt is a unit of organisation, not of compute.
- Read `assets/checks.md`: its required items apply to every search; choose conditional ones by the cost of a wrong
  result, and record "N/A because …" for the rest.

## 7. Plan and approval
Copy `assets/RUN_PLAN.md` to the project root and fill it: the light section for a light search (one approval covers
the whole search), part A for a heavy one (part B follows after Phase 2). Show it and ask the user to approve or amend
it. Nothing costly runs before approval.

## Context dump
Create `CONTEXT.md` from `assets/CONTEXT.md`: status block and project facts (evaluator commands, data, optimizer),
pointing to `RUN_PLAN.md` rather than copying it. A fresh agent must be able to resume from these two files. Suggest
compacting the conversation if this phase left bulky output.
