---
name: baseline_model
description: Second phase. Implement a simple baseline model with a parameterized signature, test the full pipeline end-to-end using a sub-agent, and verify outputs are plausible before the iterative loop.
entry: `CONTEXT.md` present.
exit: Baseline model defined; end-to-end pipeline verified by sub-agent; CONTEXT.md updated.
---

# Phase 2 — Baseline Model

---

## Steps

### 1. Baseline model
Program a first, intentionally simple model in a `model.X` file (`X` = `.py`, `.m`, `.r`, etc.). The goal is a working skeleton, not a good model.

- Accept parameters as an explicit function argument with reasonable defaults — this makes it easy for the optimization routine to sweep parameter values without changing the call signature.
- Implement a **shared attempt harness** that every agent calls instead of writing its own driver: given an attempt
  folder, it fits the model, evaluates it with the agreed protocol, appends one fixed-schema record (structure,
  complexity, metrics, runtime, convergence, seed) to a common results file (one write per record, so parallel agents
  do not interleave), and writes a metrics card (`card.md`, first
  line a one-line summary). This keeps results comparable and saves agents' tokens. For heavy searches it also submits
  long jobs, leaves `attempt_i/.job` while one runs, and offers a wait command that blocks up to a given time and then
  reports the job's state (`assets/resources.md` §3).

### 2. End-to-end test via sub-agent
**Use a sub-agent** to run the full pipeline on a small data subset (one or two reference models at default fit
settings; the full reference scoring is step 4):
- Train/calibrate the model using the optimization routine
- Generate predictions
- Log all metrics (including run-time and memory)

This step is critical: it confirms that sub-agents can read/write files and execute code *before* the iterative loop begins.

It is also the first **cost calibration**: record the time and compute of one evaluation and the sub-agent's wall
time (heavy searches: also its model, effort and usage). Phase 3 scales these to estimate a meta-iteration
(`assets/resources.md` §5); revisit the light/heavy classification if the evaluation time differs from Phase 1's guess.
For a heavy search, the test also exercises job submission, the wait command, the `.job` marker and harvesting after
an interruption.

### 3. Sanity check
Verify:
- Model produces plausible outputs (outputs in expected range, no NaNs or infinities)
- Optimization problem is well-posed (convergence achieved, metrics not degenerate)
- Run-time and memory usage are compatible with the iterative loop planned in Phase 3

If the model fails to converge, diagnose and fix before proceeding.

### 4. References
Score the references agreed in the plan (item 8) at the default fit settings; refit deeply (more restarts and seeds)
only the few that will serve as incumbents. If this will take much longer than the plan said, say so before running
it.

Apply the Baseline checks adopted from `assets/checks.md` (typically the ★ ones: the evaluator reproduces reference
results, a modification at its null value reproduces the baseline, and where the baseline fails is known).

---

## Context dump (end of phase)

Update `CONTEXT.md` with:
- Mock model description (structure, key equations or code functions)
- Baseline metrics on train and validation sets (or in line with previous choices e.g. cross-val)
- Confirmed run-time and memory per optimization run
- Any environment or permission findings from the sub-agent test
- The cost calibration (evaluation time and compute; sub-agent wall time and, if heavy, usage) and the search size

Then **verify `CONTEXT.md` is self-sufficient**: a fresh agent with no conversation history should be able to resume from it alone.

If the sub-agent test left large logs in the conversation, **suggest the user compact it** before proceeding to Phase 3 — Iterate.
