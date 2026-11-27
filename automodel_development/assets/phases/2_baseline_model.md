---
name: baseline_model
entry: RUN_PLAN.md approved for setup; status says Phase 2.
exit: Harness and evaluator tested; baseline and references scored; calibration recorded (heavy: part B approved).
description: Second phase. Build the baseline and a shared attempt harness, test the evaluator and the execution path end to end, score the references, and calibrate cost.
---

# Phase 2 — Baseline Model

## 1. Baseline and shared harness
A deliberately simple baseline in `model.X` (`.py`, `.m`, `.r`, …) taking its parameters as an explicit argument, and
a **shared attempt harness**: one entry point that every agent calls instead of writing its own driver. Given a
candidate (a source file, expression or configuration), it fits, scores under the plan's decision rule and records
the result. Build it on the existing evaluator where there is one, and give each part a test.

**Every search**
- **One record per fit**, screens and failures included: stable candidate and fit IDs, proposer, stage (screen /
  scored / refit / reference), status, model, data and protocol identity, settings, seed, fitted state or an immutable
  artifact reference, metrics and stop reason. Write records atomically (one file per fit, or an append the platform
  guarantees) so parallel agents cannot corrupt each other's; refits and rescores add records and never overwrite;
  one collector builds tables and checks counts. A light search may keep one append-only results file holding every
  fit and rescore with a short rationale; there, "validated" means it holds a scored fit or a recorded failure.
- **Budget and stop in the harness:** it charges each fit when submitted, failures and restarts included; refuses
  work beyond the current allocation; and refuses new submissions once `STOP` exists in the active `meta_m/` or the
  project root. Parallel agents share one counter (e.g. under a lock file); a central loop that fits every candidate
  itself enforces this directly. A limit that depends on each agent's restraint does not hold.
- **Submit and wait in one blocking call** that prints one line per candidate: one model call per evaluation batch.
- **A sanctioned cheap screen** where full fits are expensive, so that nobody writes a private fitter that bypasses
  the counter. Other shared tools are added when an analysis recurs (`phases/3_iterate.md`, shared tools).

**Heavy searches** add the components in `heavy.md` §1 (failure command, card, toolkit, validator, long and
remote jobs).

## 2. Evaluator tests (required)
Run the required evaluator checks in `assets/checks.md`. Implement the complete decision rule once — eligibility, tie
grouping, and the order of any minimum-improvement condition for replacing the incumbent — use it in the collector
and in incumbent decisions, and test that path on a tiny fixed candidate table (the result must not depend on row
order). Tolerance ties are not a pairwise approximate-equality sort: "within tolerance" is not transitive. For a
modification that claims to contain the baseline, check that its null setting reproduces the baseline; for a
replacement structure, run a reference-output smoke test. Test the code of deferred acceptance checks on development
data too; the reserved data stay sealed. Keep these as runnable tests.

## 3. End-to-end pilot
Run the full pipeline on one or two models at default settings through the execution path the search will use: for
detached workers a one-agent, one-attempt launcher run (`meta_0`); otherwise a sub-agent (or this session, if
sub-agents are unavailable). Exercise what the chosen mode uses: fitting, prediction, records, the budget and `STOP`,
and any flexible fit Phase 1's gate-feasibility check deferred to here. Heavy searches also exercise the card and the
validator and, each where the run uses it, job submission, waiting, the `.job` marker and harvesting (after an
interruption and with one output missing or truncated), the exact remote submission (shell expansion on the remote
side, resource requests against node sizes, unhealthy nodes) and the rules carried into `WORKER_RULES.md`. Record the
time and compute of one evaluation and the pilot's wall time (heavy: model, effort, model calls and context per
session), and revisit the light/heavy classification and the starting defaults of `resources.md` §3 if they differ
from Phase 1's estimate. Install new dependencies only outside the reference environment; generate the brief's
statements about the data (ranges, spacing, units) from the data; heavy: list the tools the pilot's agent wrote as
toolkit candidates.

## 4. References and baseline
Score the plan's references and the baseline at default settings; refit deeply (more starts, new seeds) only those
that will be incumbents. References in the final comparison are refitted in Phase 4 where their fitting is under the
plan's control (`checks.md`, uncertainty and references). If this will take much longer than the plan said, tell the
user before running it. Profile where the baseline fails (by region, group or regime) and how much error comes from
any component that stays fixed.

## 5. Calibration and approval (heavy)
Update the estimates using `resources.md` §4. Fill `RUN_PLAN.md` part B and get it approved.

## Context dump
Update the status block and project facts in `CONTEXT.md`: baseline and reference scores, evaluation time and memory,
harness commands, test results, calibration. Suggest compacting if the pilot left bulky logs.
