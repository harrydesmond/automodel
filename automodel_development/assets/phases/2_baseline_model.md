---
name: baseline_model
entry: RUN_PLAN.md approved for setup; status says Phase 2.
exit: Harness and evaluator tested; baseline and references scored; calibration recorded (heavy: part B approved).
description: Second phase. Build the baseline and a shared attempt harness, test the evaluator and the execution path end to end, score the references, and calibrate cost.
---

# Phase 2 — Baseline Model

## 1. Baseline and shared harness
- A deliberately simple baseline in `model.X` (`.py`, `.m`, `.r`, …) taking its parameters as an explicit argument.
- A **shared attempt harness** that every agent calls instead of writing its own driver. Given a candidate (a source
  file, expression or configuration), it fits, scores under the plan's decision rule, and writes:
  - one structured **record per fit**, screens and failures included: stable candidate and fit IDs, proposer, stage
    (screen / scored / refit / reference), status, model, data and protocol identity, settings, seed, fitted state or an immutable artifact reference when available, metrics and stop reason. Write records atomically (one file per fit, or an append the platform guarantees); one collector builds
    tables and checks counts. Refits and rescores add records; they never overwrite.
  - a metrics card (`card.md`, first line a one-line summary) generated from the record;
  - a completion validator (`done_attempt.sh <attempt_dir>`): exit 0 only when every required variant/control has a
    validated result or recorded failure and no job remains pending; otherwise non-zero. Review quarantines failures.
  It also offers a command that records a failure it cannot detect itself (e.g. a lost job) with its reason; agents
  never write records or results by hand.
  Light searches may keep one small append-only file per candidate holding every fit and rescore (with a short
  rationale) and skip cards and the validator file; count fits inside the harness.
- The harness counts evaluations against the plan's budget and refuses work beyond it, and refuses new submissions
  once a STOP file exists; parallel agents and post-processing hooks share one counter (e.g. under a lock file).
- Heavy searches: it also submits long jobs, leaves `attempt_i/.job` (how to harvest) while one runs, and offers a wait
  command that blocks up to a given time and then reports the job's state.

## 2. Evaluator tests (required)
Run the required evaluator checks in `assets/checks.md`. Implement the complete decision rule once — eligibility, tie grouping, and the order of any
minimum-improvement condition for replacing the incumbent — use it in the collector and in incumbent decisions, and
test that path on a tiny fixed candidate table (the result must not depend on row order). Tolerance ties are not a
pairwise approximate-equality sort: "within 1 nat" is not transitive. For a modification that claims to contain the baseline, check that its null setting reproduces
the baseline; for a replacement structure, run a reference-output smoke test. Keep these as runnable tests.

## 3. End-to-end pilot
Use a sub-agent (or this session, if sub-agents are unavailable) to run the full pipeline on one or two models at
default settings, through the execution path the search will use (local, cluster, detached workers): fit, predict,
record, card, validator; for heavy searches also job submission, waiting, the `.job` marker and harvesting after an
interruption. Record the time and compute of one evaluation and the pilot's wall time (heavy: its model, effort and
usage), and revisit the light/heavy classification if they differ from Phase 1's estimate.

## 4. References and baseline
Score the plan's references and the baseline at default settings; refit deeply (more starts, new seeds) only those
that will be incumbents. If this will take much longer than the plan said, tell the user before running it. Profile
where the baseline fails (by region, group or regime) and how much error comes from any component that stays fixed.

## 5. Calibration and approval (heavy)
Update the estimates using `resources.md` §5. Fill `RUN_PLAN.md` part B and get it approved.

## Context dump
Update the status block and project facts in `CONTEXT.md`: baseline and reference scores, evaluation time and memory,
harness commands, test results, calibration. Suggest compacting if the pilot left bulky logs.
