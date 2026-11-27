---
name: finalize
entry: The search ended (stop rule, budget, or the user's instruction); CONTEXT.md records the best eligible candidate, or that none exists.
exit: Outcome, metrics, limitations and job status recorded in CONTEXT.md.
description: Fourth and final phase. Validate and freeze authorised finalists, apply any agreed external check, and record the outcome, including an unsuccessful one.
---

# Phase 4 — Finalize

## 1. Validate and freeze
All final work uses the plan's reserve (what consolidation left of it) and obeys the latest stop instruction. If no
eligible candidate exists, record that without another fit; reserved data then stay sealed.

For the finalists the user chose, exercise the script that applies the acceptance checks and the interface through
which the model will be used, on development data, including
relevant branches and boundaries. Record failures; repair only within scope, then revalidate and freeze the model,
fitted state and evaluation dependencies (the model tested must be the model selected). Verify their identities when evaluating or reporting. For heavy searches,
generate the gate decision from complete records; missing, non-finite or insufficient coverage cannot pass.

## 2. External check, if agreed
Before opening reserved evidence, record candidates, baseline, decision rule and claims in version control and have
the user approve this pre-registration (approving the external check at setup does not cover it: candidates and
claims must be fixed after the search and before anyone sees the reserved data, or they can be chosen to fit it). Check a
clean checkout can recover the approved inputs and run the checks, using tracked files or documented immutable assets.
Apply the pre-registered check and report all agreed metrics.

Without external evidence, reverify the winner from its records within the allowance; identify anything not rechecked
and qualify predictive claims for adaptive selection. Validation gains can shrink on independent data; agreement does not prove absence of selection bias.
A failed gate stays failed: report it and let the user choose between accepting the disclosed limitation and changing
the candidate, which then needs new independent evidence.

## 3. Corrections and later versions
Preserve original outcomes and version changes. Recheck affected claims and test preserved behaviour to the declared
tolerance. Corrected evaluation of frozen candidates and the reference may reuse evidence, labelled as such. Data used to choose revisions
become development evidence; new independent predictive claims need fresh evidence or an exploratory label.
Deterministic constraints remain reusable. Re-reading a spent set for added statistics needs the user's approval and a label.

## 4. Record
In `CONTEXT.md`: decision (accept / exploratory / no useful improvement / do not use), selected model and entry point,
metrics, checked claims and their populations, limitations, and job status. Sampled accuracy is not a region-wide
guarantee. Stop owned jobs and processes. See `checks.md` for conditional stress tests and audits.
