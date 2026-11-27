---
name: setup
entry: No `CONTEXT.md` in the project root, or its status says Phase 1.
exit: RUN_PLAN.md approved (light: whole plan; heavy: part A); CONTEXT.md created.
description: First phase. Agree the goal, data, decision rule, external evidence, budget and execution path; record them in RUN_PLAN.md and get approval.
---

# Phase 1 — Setup
Reuse explicit answers and delegation; ask the open questions together and follow up on any left unanswered
(`SKILL.md`).

## 0. Feasibility and size
Inspect the runtime, libraries, tools and delegation (`resources.md` §§1–2). Decide which data are reserved before any
scoring. Time a cheap evaluation, otherwise estimate it, and classify the search. Heavy: read `heavy.md` and the
applicable adapters; agree the limits on usage, wall time and compute, which are hard, and how each is enforced.
Detached: read `detached.md`, run `<skill>/scripts/tests/run_tests.sh` on the launcher's intended host (for a cluster,
in a short job on that kind of node), and agree permissions and any unattended period. If unsupported, use a simpler
path.

## 1. Goal and claims
Agree the terminology, what the model is for (input range, extrapolation, derivatives, runtime or interpretability),
required properties and the scope of the final claims. Read the project's `references/`.

## 2. Existing code and data
Identify reusable code, data identity, variables, units, cleaning, groups and independent datasets (keep these for
replication); choose informative, affordable references (`checks.md`).

## 3. Objective
- Agree the training objective and reported metrics, including runtime and memory. Classify each requirement as a hard
  search gate, a deferred acceptance check, a score term or a diagnostic, with its statistic, population and phase.
  Downstream claims require the actual downstream analysis and its assumptions; otherwise label them diagnostic.
- Gate feasibility: on development evidence, test each gate on known passes and failures and on the references, and
  establish a credible candidate in the allowed family that passes all gates together (expensive fitting can wait for
  Phase 2's pilot). An unconstrained optimum failing a gate reveals a trade-off, not a defect. Specify how each search
  gate is enforced: constrained fitting, or a penalty that steers fits with remaining failures rejected. Escalate
  implementation errors, or the lack of a credible jointly feasible candidate. Check gates beyond the points used to
  set them.
- Predictive selection with an unpenalised score uses a validation set or grouped, stratified or time-ordered
  cross-validation. A descriptive in-sample comparison needs explicit complexity limits and makes no independent
  predictive claim. An agreed information criterion may use all development data; distinguish descriptive from
  predictive goals, since a complexity penalty does not remove adaptive-selection optimism. Set a hybrid's penalty
  against the noise of its held-out score.
- Read back the rule: "Among candidates passing [hard search gates, over their domain], rank by [score and
  direction], with [tie grouping and promotion margin]; [other checks] are reported only." Show how a known reference
  ranks or is excluded (compute it if cheap), and which references the gates exclude. List deferred acceptance checks
  separately. A later change to the rule needs approval, a new protocol version and comparable rescores.
- For constants that depend on score noise (tie tolerance, promotion margin; `checks.md`, score noise), approve the
  calibration method now, measure on development fits in Phase 2, and fix the value in `RUN_PLAN.md` before any
  candidate is scored. This completes the approved rule rather than changing it.

## 4. Splits and external evidence
Define the splits or folds; prevent leakage between entities, in time and through duplicates; fit preprocessing
within each training split. Agree a reserved test set, independent replication or an out-of-range constraint check
(which tests admissibility, not predictive accuracy); only if none is affordable and the user agrees, the result is
"exploratory, no independent check". Record what the criterion does not account for, including the adaptive search
over candidates.

Store reserved data, and every result on them (references' included), outside every tree that workers or harness
commands read; the evaluator refuses them before any scoring. Record prior exposure and pools shared with sibling
runs, what may be refitted at the final check, and access to fresh evidence for later claims. Development results of
references stay visible unless the plan blinds them, saying why.

## 5. Optimization routine
Agree an existing or library-based training or calibration routine with seeds, restarts and a stop criterion or fixed
schedule.

## 6. Budget and checks
One ledger with four allocations: setup and calibration; search; consolidation; protected final checks with their
reference refits. Light: fit and elapsed-time caps; heavy: also screens and scored fits per attempt and a compute cap.
Every training or calibration run is a fit, closed-form ones included, and so is every restart and fold; report
candidate counts separately. Wall time includes outages and excludes agreed review pauses. An attempt is not a unit of
compute. Classify each limit and its enforcement (`resources.md` §4).

Apply the required items of `checks.md` and choose conditional ones by cost and stakes; record those adopted and any
omission that limits a claim.

## 7. Plan and approval
Fill the applicable plan template as `RUN_PLAN.md` (heavy: part A now, part B after calibration) and create
`CONTEXT.md` from its template, with the status, project facts and a pointer to the plan; a fresh agent must be able
to resume from these two files. Write both to disk first, then present the plan for approval; nothing costly runs
before it.
