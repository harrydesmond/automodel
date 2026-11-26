---
name: baseline_model
entry: RUN_PLAN.md approved for setup; status says Phase 2.
exit: Harness and evaluator tested; baseline and references scored; calibration recorded (heavy: part B approved).
description: Second phase. Build the baseline and a shared attempt harness, test the evaluator and the execution path end to end, score the references, and calibrate cost.
---

# Phase 2 — Baseline Model

## 1. Baseline and shared harness
A deliberately simple baseline in `model.X` (`.py`, `.m`, `.r`, …) taking its parameters as an explicit argument, and
a **shared attempt harness** that every agent calls instead of writing its own driver: given a candidate (a source
file, expression or configuration), it fits, scores under the plan's decision rule and records the result. Every later
phase relies on it; give each part a test.

**Every search**
- **One record per fit**, screens and failures included: stable candidate and fit IDs, proposer, stage (screen /
  scored / refit / reference), status, model, data and protocol identity, settings, seed, fitted state or an immutable
  artifact reference, metrics and stop reason. Write records atomically (one file per fit, or an append the platform
  guarantees) so parallel agents cannot corrupt each other's; refits and rescores add records and never overwrite;
  one collector builds tables and checks counts. Light searches may keep one append-only file per candidate holding
  every fit and rescore with a short rationale; there, "validated" means the file holds a scored fit or a recorded
  failure.
- **A failure command** that records what the harness cannot detect itself (e.g. a lost job) with its reason: agents
  never write records or results by hand, so every number traces to a fit.
- **One budget counter**, shared by parallel agents and hooks (e.g. under a lock file), that refuses work beyond the
  plan's budget and new submissions once `STOP` exists in the active `meta_m/` or the project root: a limit that
  depends on each agent's restraint does not hold.
- **A shared toolkit** of the analyses agents would otherwise each write: evaluation at fixed constants, residual
  breakdowns, per-gate diagnostics (which component fails and by how much), oracle floors and, where the model family
  allows it, the gain of adding a component with the rest held fixed. Where full fits are expensive, add a sanctioned
  cheap screen, so that nobody writes a private fitter that bypasses the counter.
- **Submit and wait in one blocking call** that prints one line per candidate: one model call per evaluation batch.

**Heavy searches, in addition**
- **A metrics card** (`card.md`, first line a one-line summary) generated from the record, carrying the diagnostics
  agents need most (error breakdowns by the main data dimensions and the regions the requirements single out), so
  agents do not each re-derive them.
- **A completion validator** `done_attempt.sh <attempt_dir>`: exit 0 only when every required variant or control
  has a validated result or recorded failure and no job remains pending. The launcher and the review trust it, not
  prose; the review quarantines failures.
- **Long jobs:** submission that leaves `attempt_i/.job` (how to harvest) while one runs; a wait command that blocks
  up to a given time and then reports the job's state; a non-blocking job-state command (running / finished but not
  collected / none) for the launcher's `job_state.sh` hook. Under phase sessions, submit returns once the receipt is
  written and the worker ends its session.
- **Remote evaluation:** check before every submission that the remote code matches the local code; jobs write
  outputs atomically (temporary file, then rename); harvesting records a missing, unreadable, empty or truncated
  output as a failed work unit with its reason and carries on, since stopping on one would block the attempt.

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
interruption and with one output missing or truncated. Record the time and compute of one evaluation and the pilot's wall time (heavy: its model, effort and
usage), and revisit the light/heavy classification if they differ from Phase 1's estimate. The pilot also checks the
exact remote submission (shell expansion on the remote side, resource requests against node sizes, unhealthy nodes),
installs new dependencies only outside the reference environment, measures tokens per agent session, and lists the
tools its agent wrote as toolkit candidates. Generate the brief's statements about the data (ranges, spacing, units)
from the data.

## 4. References and baseline
Score the plan's references and the baseline at default settings; refit deeply (more starts, new seeds) only those
that will be incumbents. If this will take much longer than the plan said, tell the user before running it. Profile
where the baseline fails (by region, group or regime) and how much error comes from any component that stays fixed.

## 5. Calibration and approval (heavy)
Update the estimates using `resources.md` §5. Fill `RUN_PLAN.md` part B and get it approved.

## Context dump
Update the status block and project facts in `CONTEXT.md`: baseline and reference scores, evaluation time and memory,
harness commands, test results, calibration. Suggest compacting if the pilot left bulky logs.
