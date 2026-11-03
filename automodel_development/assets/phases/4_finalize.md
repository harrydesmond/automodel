---
name: finalize
description: Fourth and final phase. Evaluate the best model against the external check agreed in Phase 1, decide whether to return to Iterate or accept results, and record the final outcome in CONTEXT.md.
entry: User satisfied with the selection score; CONTEXT.md has pointer to best model
exit: CONTEXT.md updated with final decision, test metrics, and key handoff details.
---

# Phase 4 — Finalize

---

## Steps

### 1. Restore context
Read `CONTEXT.md` to identify the best model path and its selection score.

### 2. Pre-register
Before the external check, record the models to be tested, the decision rule and the claims (commit them if the project
is under version control); see the Finalize section of `assets/checks.md` for claim stress tests and audits that may
apply.

### 3. Final evaluation
Apply the external check agreed in Phase 1: evaluate the best model on `test.X`, or run the agreed alternative (replication on an independent dataset, or the constraints the form must satisfy outside the fitted range). If the user agreed to none, re-verify the selected model from scratch (refit and score) and state in the outcome that its score is optimistically biased by the search. Report all metrics defined in Phase 1 (including run-time and memory).

### 4. Decide
- If the check comes out significantly worse than the search suggested: discuss with the user whether to return to Phase 3 — Iterate. **If you do, do not keep re-using the same check** — each repeated peek erodes its independence and reintroduces the overfitting it was meant to catch. Advise the user to obtain fresh data, or a fresh check, before iterating further.
- If the check is acceptable: finalize.

## Context dump (end of phase)

Complete the Phase 4 — Finalize section of `CONTEXT.md` with:
- Final decision and selected model path;
- Concise usage entry point;
- Final validation and test metrics, including runtime and memory;
- Interpretation of the validation-to-test difference;
- Acceptance-criteria results;
- Most important limitations.
