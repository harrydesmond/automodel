---
name: baseline_model
entry: RUN_PLAN.md approved for setup; status says Phase 2.
exit: Harness and evaluator tested; baseline and references scored; calibration recorded (heavy: part B approved).
description: Second phase. Build the baseline and a shared attempt harness, test the evaluator and the execution path end to end, score the references, and calibrate cost.
---

# Phase 2 — Baseline Model

## 1. Baseline and shared harness
Implement a deliberately simple baseline with explicit fitted state, and, building on any existing evaluator, one
entry point that every agent calls instead of writing its own driver: it accepts a candidate (code, expression or
configuration), fits, scores and records it under the plan. Test each applicable part.
- An append-only, atomic record per fit (screens, failures, refits and rescores included): stable candidate and fit
  IDs, proposer, stage, status, model, data and protocol identities, settings, seed, fitted state or an immutable
  reference to it, metrics, stop reason and a brief rationale. One collector reconciles counts and generates tables.
  Light: one append-only results file suffices; an attempt is validated only once every required result or failure is
  recorded and no job remains pending. Eligibility is checked separately.
- Charge fits at submission, every restart and failure included. Enforce the allocation and `STOP` (in the active
  `meta_m/` or the project root); concurrent workers and hooks share atomic reservations, and a central evaluator may
  enforce this directly. After a cutoff, admit no new evaluations but harvest admitted work.
- Submit and collect each batch in one cycle with compact results (a blocking call where supported). Where full fits
  are expensive, provide a sanctioned screen that goes through the counter; add reusable tools when needed.

Heavy: add the failure command, card, toolkit and validator of `heavy.md` §1, and its long and remote job handling
where used.

## 2. Evaluator tests (required)
Run the required tests of `checks.md`. Implement the eligibility, ranking, tie and promotion rule once for the
collector and incumbent decisions, and test it on a tiny fixed table in varied row order (approximate equality is not
transitive). A nested modification must reproduce the baseline at its null setting; a replacement structure gets a
reference-output smoke test. Test deferred acceptance code on development data, never on reserved evidence. Keep the
tests runnable.

## 3. End-to-end pilot
Run one or two default models through the actual execution path (detached: one agent and one attempt in `meta_0`;
otherwise an agent or this session). Exercise fitting, prediction, records, the budget, `STOP` and any gate-feasibility
fit deferred from Phase 1. Heavy: the card and validator; where used, submission, waiting, receipts and
harvesting after an interruption and with missing or truncated outputs; remote shell expansion, resource requests and
node health; the worker rules carried over. Record one evaluation's time and compute, the pilot's wall time and the
model, effort, calls and context the runtime exposes; revise the size class and session guides. Keep new dependencies
outside the reference environment, derive the brief's data facts from the data, and note reusable tools from the
pilot.

## 4. References and baseline
Score the agreed references and the baseline at their declared settings; refit deeply only likely incumbents
(controlled references in the final comparison are refitted in Phase 4). Tell the user before work that will cost
much more than planned. Diagnose where the baseline fails (regions, groups, regimes) and the error from components
that stay fixed.

## 5. Calibration and approval (heavy)
Update the estimates (`resources.md` §4), complete part B and obtain approval.

## Context dump
Update `CONTEXT.md` with scores, harness commands and tests, time and memory, and calibration; checkpoint (`SKILL.md`).
