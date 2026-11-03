---
name: finalize
entry: The search ended (stop rule, budget, or the user's instruction); CONTEXT.md records the best eligible candidate, or that none exists.
exit: Outcome, metrics, limitations and job status recorded in CONTEXT.md.
description: Fourth and final phase. Pre-register, apply the agreed external check to an authorised frozen candidate, decide, and record the outcome, including exploratory or unsuccessful ones.
---

# Phase 4 — Finalize

## 1. Pre-register (if there is an external check)
Before it, record (and commit, under version control) the candidates to test, the baseline treated the
same way, the decision rule and the claims. If a final refit frees constants or changes structure, validate the result
before the check: the model tested must be the model selected.

## 2. External check
Final checks and refits use only an agreed remaining or reserved allowance and obey the user's latest stop
instruction. Apply the agreed check to the authorised frozen candidate(s): the held-out set, independent data, or
out-of-range constraints, reporting all agreed metrics including runtime and memory. Without an external check, verify
the winner from its recorded parameters, score and completed convergence checks (fit again only within the allowance)
and state that its score is optimistic because of the search; otherwise close from the validated records and say what
was not rechecked. If no eligible candidate exists, record that without another fit. Unused reserved data stay sealed.

## 3. Decide
- Validation-to-test shrinkage is normal; agreement shows consistency, not absence of selection bias.
- If held-out results guide further selection, those data become development evidence: an independent predictive
  claim then needs fresh data. Deterministic constraints (positivity, symmetries) may be reused as acceptance tests;
  once they guide revisions, record them as selection requirements.
- After a data or evaluator correction: keep the original results, record the change, recheck the frozen candidates
  and the reference under the same rule and label the check as reused. Structures or rules chosen from those outcomes
  need fresh independent evidence, or are reported as exploratory.

## 4. Record
In `CONTEXT.md`: decision (accept / exploratory result / no useful improvement / do not use), selected model and usage
entry point, validation and external metrics, interpretation of the difference, which claims were checked on what
(sampled accuracy is not a region-wide guarantee), main limitations, and confirmation that no job or process is left
running. See `assets/checks.md`, Finalize, for stress tests and audits that may apply.
