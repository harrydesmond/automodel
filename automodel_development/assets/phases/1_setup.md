---
name: setup
entry: No `CONTEXT.md` in the project root, or its status says Phase 1.
exit: RUN_PLAN.md approved (light: whole plan; heavy: part A); CONTEXT.md created.
description: First phase. Agree the goal, data, decision rule, external evidence, budget and execution path; record them in RUN_PLAN.md and get approval.
---

# Phase 1 — Setup

Reuse answers the user has already given (in this conversation, project instructions or memory) and mark them
[user chose] or [delegated]; ask only what is open. Ask related questions together, listed explicitly in your message,
and follow up on any that come back skipped or partly answered.

## 0. Feasibility and size
- Confirm language/runtime and libraries, and whether sub-agents can be spawned with file and shell access. If not,
  agents run sequentially in this session; record that.
- Time one evaluation (a fit plus scoring) if it takes seconds; otherwise estimate or ask how long it takes and where
  it runs, and classify the search as light or heavy (`assets/resources.md` §1). Heavy: read `assets/heavy.md` and
  the adapters for the frameworks the run will use (`assets/adapters/`); ask the user's limits on usage, wall time and
  compute, and which of them are hard; choose in-session or detached workers (`resources.md` §2). With detached
  workers, run `<skill>/scripts/tests/run_tests.sh` where the launcher will run (for a cluster job, in a short job on
  that kind of node), ask which permissions the user will approve, and ask whether the run must continue while the
  user is away: the launcher's host and the work queued for the absence are then plan decisions (`detached.md` §3).
- Decide which data are reserved (§4) before scoring anything, so that no setup score touches them.

## 1. Goal and claims
Domain vocabulary (loss vs cost, features vs covariates…); what the model is for (input range, extrapolation,
derivatives, runtime vs interpretability); required properties (positivity, monotonicity, symmetries, physical limits);
what the final claims will cover. Check the project's `references/` folder.

## 2. Existing code and data
Review existing code with the user and decide what to reuse. Identify the data files, input and output variables,
cleaning needs, groups (subjects, sites, datasets) and every other dataset available (keep independent ones for
replication). Choose the references to compare against (`checks.md`, uncertainty and references).

## 3. Objective
- **Training loss** and **reported metrics**; always include runtime and memory per evaluation.
- **Requirements**: decide for each whether it is a hard gate (candidates failing it are rejected), part of the score,
  or reported only; specify its statistic and population and, for a gate, whether it applies during the search or is
  an acceptance check deferred to Phase 4. A claim about the impact on a downstream analysis requires running that
  analysis with its own assumptions; otherwise label the claim diagnostic.
- **Gate feasibility:** test each gate's implementation on cases known to pass and to fail it and on the references,
  and establish that the allowed model family contains a credible candidate that passes it (with expensive fits, a
  flexible fit in Phase 2's pilot). An unconstrained optimum that fails a gate shows a trade-off between fit and
  constraint, not a defect: report it and decide how the search enforces the gate (constrained fitting, or a penalty
  that steers fits, with candidates that still fail it rejected). Escalate implementation errors, and requirements no
  credible candidate meets together. Check gates at held-out points too, not only where they were set. Use
  development data for all of this.
- **Selection score**:
  - Not complexity-penalised (RMSE, log-loss, …): for predictive selection, measured out of sample on a validation
    set or by (grouped, stratified or time-ordered) cross-validation. A deliberately descriptive in-sample comparison
    is allowed with explicit complexity limits and no independent predictive claim.
  - Complexity-penalised (an information criterion, MDL, …): an agreed, well-defined criterion may rank candidates on
    all the data; a validation split is not needed merely to compute it. Decide separately whether the goal is a
    descriptive comparison or predictive generalisation, and whether independent evidence is affordable. A penalty does
    not make the winner of an adaptive search reliable by itself.
  - Hybrid (held-out error plus a penalty): set the penalty against the noise of the held-out score.
- **Read back the operative rule** in one sentence — "Among candidates satisfying [hard requirements over their
  domain], rank by [score and direction]; [other checks] are reported only" — and show how one known reference is
  ranked or rejected under it (compute its score if an evaluation takes seconds), and say which known references the
  gates exclude. Changes to this rule later are
  protocol changes (new version, rescoring).
- A constant of the rule that depends on score noise (a tie tolerance, a replacement margin; `checks.md`,
  score noise) can often be measured only in Phase 2: approve the method now, then fix the value in `RUN_PLAN.md`
  before any candidate is scored. That completes the approved rule; it is not a protocol change.

## 4. Splits and external evidence
- Create the data files the score needs, if any (`train.X`, `validation.X` or folds); guard against leakage (repeat
  measurements of one entity across splits, time-series autocorrelation, duplicates).
- Agree the external check for Phase 4: a held-out test set, replication on independent data, or out-of-range
  constraints. Constraints assess admissibility, not predictive accuracy. If none is affordable, the user may agree to
  "exploratory, no independent check"; record what the criterion does not pay for (the number of candidates tried).
- A reserved dataset is excluded from the agents' inputs and refused by the evaluator before any scoring, references
  included. Record earlier exposure (e.g. benchmarking references on it) and sibling runs sharing it, and state what
  may be refitted at the final check. For later independent claims, plan access to fresh evidence.
- Keep reserved data, and every result computed on them (references' included), outside the tree that agents and
  their harness commands read. Development scores of references stay visible; if the plan blinds anything else from
  agents, it says what and why.

## 5. Optimization routine
Implement or confirm a parameter optimizer (prefer libraries), with seeds, restarts and a stop criterion.

## 6. Budget and checks
- Evaluation budget, as one ledger: setup and calibration; the search; consolidation (discretionary refits and
  recombinations at the end); the final checks with the reference refits they need (protected). Light: fit and
  wall-time caps; heavy: also screens and scored fits per attempt and a compute cap. A fit is one training or
  calibration run of one candidate on one training set, closed-form methods included; each restart and each fold is a
  fit, reported alongside the candidate count. Wall time is elapsed time while the search runs, outages included and
  the user's review pauses excluded. An attempt is a unit of organisation, not of compute.
- For each limit, record its kind (estimate, submission cutoff or execution limit) and how it is enforced
  (`resources.md` §4).
- Read `assets/checks.md`: its required items apply to every search; adopt conditional ones by the cost of a wrong
  result. Record the checks adopted, and an omission only where it limits a claim.

## 7. Plan and approval
Copy the template for the search's size (`assets/RUN_PLAN_light.md` or `assets/RUN_PLAN_heavy.md`) to the project
root as `RUN_PLAN.md` and fill it (heavy: part A now, part B after Phase 2). Write it and `CONTEXT.md` to disk first,
then show it and ask the user to approve or amend it (`SKILL.md`, working with the user). Nothing costly runs before
approval.

## Context dump
Create `CONTEXT.md` from `assets/CONTEXT.md`: status block and project facts (evaluator commands, data, optimizer),
pointing to `RUN_PLAN.md` rather than copying it. A fresh agent must be able to resume from these two files. Suggest
compacting the conversation if this phase left bulky output.
