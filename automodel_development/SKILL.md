---
name: automodel-development
description: Guides the user in discovering a better model structure (e.g. from feature transformations in logistic regression to equation terms within PDEs to neural network layer compositions) out of data. Use when the user asks to create or improve an existing model. Uses an iterative meta/inner agent loop to explore structural model modifications in parallel, sized from quick in-session searches to long runs on detached worker sessions.
license: Apache-2.0
---

# automodel
Discover the structure of a model (equation terms, features, layers) from data with a meta-agent and parallel
sub-agents.

## Phases

| Phase | Recipe | Done when |
|---|---|---|
| **1 — Setup** | `assets/phases/1_setup.md` | Plan approved (`RUN_PLAN.md`); evaluator and data ready |
| **2 — Baseline** | `assets/phases/2_baseline_model.md` | Harness tested end to end; baseline and references scored |
| **3 — Iterate** | `assets/phases/3_iterate.md` | Stop rule, budget or the user ends the search |
| **4 — Finalize** | `assets/phases/4_finalize.md` | Outcome recorded (an unsuccessful search is a valid outcome) |

## How to start or resume
1. If the project has no `CONTEXT.md`, start Phase 1 (copy `assets/CHECKLIST.md` to the project root; Phase 1
   creates `CONTEXT.md`).
2. Otherwise read its status block (phase, step, active meta-iteration, protocol version, budget, pending jobs, next
   action), check that the files it points to exist and validate, and resume the first incomplete step. A directory's
   existence is not completion. If the status is unclear, `bash <skill>/scripts/read_phases.sh` prints each phase's
   entry and exit conditions.
3. Load only the current phase's recipe; it says which supporting file to read and when.

## Working with the user
- **One plan, approved before anything costly runs.** Decisions live in `RUN_PLAN.md` (template
  `assets/RUN_PLAN.md`), each marked **[user chose]**, **[delegated]** (the user, or a standing instruction such as a
  project memory, left it to you) or **[proposed]**. Resolve every [proposed] item that changes the objective, the
  permitted work or the budget before approval. A general "your choice" does not delegate a gate or requirement that
  changes which known references are eligible: propose it and show its effect. A light search approves one compact plan once; a heavy one approves
  setup first and the search after Phase 2's calibration. Later, ask again only for a change of objective or protocol,
  work outside the delegated scope, or a material budget increase.
- **No silent defaults.** If a question is skipped, interrupted or only partly answered, ask the open part again or
  show your choice in the plan as [proposed]; never settle it unseen.
- **Visible progress.** Report before each launch, during long phases, and after every meta-iteration; pause there for
  the user's review if the plan says so (default: light searches continue, heavy searches pause). A stop request takes
  effect before any further submission.

## Supporting files
- `assets/RUN_PLAN.md`: plan template. `assets/checks.md`: required evaluator checks and a menu of conditional ones.
- `assets/resources.md`: search size (light or heavy), orchestration, waiting, models, budgets, usage accounting, re-planning.
- `assets/frameworks.md`: Claude Code and Codex mechanics (sub-agents, detached workers, waits, permissions, usage).
- `<skill>/scripts/`: `launch_workers.sh` and `worker_status.sh` (detached workers, run from the project root),
  `usage_report.py` (token usage from local session logs), `tests/run_tests.sh` (their fixture tests).
- `TIPS.md`: optional practices (uncertainty, reference models).
- References: the user may put papers, code or earlier results in the project's `references/` folder (never in this
  skill's folder, which every project shares); phases say when to read them.
