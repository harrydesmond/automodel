---
name: finalize
entry: The user confirmed the search is complete; CONTEXT.md records the finalists and the primary candidate, or that no eligible candidate exists.
exit: Outcome, metrics, limitations and job status recorded in CONTEXT.md.
description: Fourth and final phase. Validate and freeze the finalists, apply any agreed external check, and record the outcome, including an unsuccessful one.
---

# Phase 4 — Finalize

## 1. Validate and freeze
Final work spends the protected final-check allocation (after a stop, only if the user asked for it; `SKILL.md`,
ending a search) and obeys the latest stop or cancellation. If no eligible candidate exists, record that without
another fit; reserved data then stay sealed.

First refit the references in the final comparison whose fitting the plan controls, with the finalists' convergence
protocol (`checks.md`), so that gains are not measured against under-converged fits.

For the finalists (`SKILL.md`, final selection and completion), exercise the script that applies the acceptance
checks and the interface through which the model will be used, on development data, including relevant branches and
boundaries. Record failures; repair only within scope, then revalidate and freeze the model, fitted state and
evaluation dependencies (the model tested must be the model selected). Verify their identities when evaluating or
reporting. For heavy searches, generate the gate decision from complete records; missing, non-finite or insufficient
coverage cannot pass.

## 2. External check, if agreed
Before opening reserved evidence, commit a pre-registration to version control: the frozen finalists, the primary
candidate whose result the claims rest on, the baseline, the decision rule and the claims. Fixing these after the
search and before anyone sees the reserved data stops them being chosen to fit it. The user approves it when the
final choice went to them or it departs from the approved plan. Check a clean checkout can recover the approved inputs
and run the checks, using tracked files or documented immutable assets. Apply the pre-registered check and report all
agreed metrics for every finalist tested. The primary candidate's result is the confirmatory one; preferring another
finalist for its reserved-data score is exploratory unless the selection is accounted for explicitly.

Without external evidence, reverify the winner from its records within the allowance; identify anything not rechecked
and qualify predictive claims for adaptive selection. Validation gains can shrink on independent data; agreement does
not prove absence of selection bias. A failed gate stays failed: report it and let the user choose between accepting
the disclosed limitation and changing the candidate, which then needs new independent evidence.

## 3. Corrections and later versions
Preserve original outcomes and version changes. Recheck affected claims and test preserved behaviour to the declared
tolerance. Corrected evaluation of frozen candidates and the reference may reuse evidence, labelled as such. Data used
to choose revisions become development evidence; new independent predictive claims need fresh evidence or an
exploratory label. Deterministic constraints remain reusable. Re-reading a spent set for added statistics needs the
user's approval and a label.

## 4. Record
In `CONTEXT.md`: decision (accept / exploratory / no useful improvement / do not use), selected model and entry point,
metrics, checked claims and their populations, limitations, and job status. Sampled accuracy is not a region-wide
guarantee. Stop owned jobs and processes. See `checks.md` for conditional stress tests and audits.
