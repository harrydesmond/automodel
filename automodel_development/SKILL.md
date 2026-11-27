---
name: automodel-development
description: Development version of automodel: discovers a better model structure from data (feature transformations, equation terms in ODEs or PDEs, neural-network layer compositions) with a meta-agent directing parallel sub-agents or detached worker sessions, from quick in-session searches to multi-day cluster runs. Only invoked when the user explicitly asks for /automodel-development, "use automodel-development" or the development version of automodel, including resuming such a run. Requests that name plain automodel, or ask for a model-structure search without naming this skill, do not invoke it.
license: Apache-2.0
---

# automodel
Discover the structure of a model (equation terms, features, layers) from data with a meta-agent and parallel
sub-agents.

## Phases

| Phase | Recipe | Done when |
|---|---|---|
| **1 — Setup** | `assets/phases/1_setup.md` | Plan approved (`RUN_PLAN.md`); `CONTEXT.md` created |
| **2 — Baseline** | `assets/phases/2_baseline_model.md` | Harness tested end to end; baseline and references scored |
| **3 — Iterate** | `assets/phases/3_iterate.md` | The user confirms the search is complete |
| **4 — Finalize** | `assets/phases/4_finalize.md` | Outcome recorded (an unsuccessful search is a valid outcome) |

## How to start or resume
1. If the project has no `CONTEXT.md`, start Phase 1, which creates it.
2. Otherwise read its status block (phase, step, active meta-iteration, protocol version, budget, pending jobs, next
   action), check that the files it points to exist and validate, and resume the first incomplete step. A directory's
   existence is not completion. Where status and disk disagree (a recorded launcher or job no longer running, a
   missing file), trust the disk: reconcile jobs from their receipts, reclaim stale locks with the launcher, and tell
   the user what you found, what you will restart and what it may still spend against the remaining budget, before
   starting anything. If the phase is unclear, `bash <skill>/scripts/read_phases.sh` prints each phase's entry and
   exit conditions.
3. Load only the current phase's recipe; it says which supporting file to read and when.

## Working with the user
This section is the one authority on approval, final selection, completion, stopping and checkpoints; the phase
recipes point here.
- **One plan, approved before anything costly runs.** Decisions live in `RUN_PLAN.md` (templates
  `assets/RUN_PLAN_light.md`, `assets/RUN_PLAN_heavy.md`), each marked **[user chose]**, **[delegated]** (the user,
  or a standing instruction such as a project memory, left it to you) or **[proposed]**. Resolve every [proposed]
  item that changes the objective, the permitted work or the budget before approval. A general "your choice" does not
  delegate a gate or requirement that changes which known references are eligible: propose it and show its effect. A
  light search approves one compact plan once; a heavy one approves setup first and the search after Phase 2's
  calibration. Later, ask again only for a change of objective or protocol, work outside the delegated scope, a
  material budget increase, a final choice with a trade-off, or confirmation that the search is complete.
- **Final selection and completion.** At the end of the search, recommend the finalists and the primary candidate
  under the decision rule. A clear winner under the rule becomes the primary candidate for later stages without
  asking; a trade-off the rule leaves open (a required gate no finalist meets, candidates the rule cannot separate
  that differ in other respects, a claim beyond the plan) goes to the user. Heavy searches report the possible
  finalists and the recommendation in every case. The search is complete, and Phase 4 starts, only when the user
  says so explicitly: they may want to improve on the best candidate first.
- **No silent defaults.** If a question is skipped, interrupted or only partly answered, ask the open part again or
  show your choice in the plan as [proposed]; never settle it unseen.
- **Visible progress.** Report before each launch, during long phases, and after every meta-iteration; pause there for
  the user's review if the plan says so (default: light searches continue, heavy searches pause).
- **Ending a search.** A *planned end* (the stop rule fires, M is reached or the search allocation is spent) opens
  the consolidation allocation; the protected final-check allocation opens with Phase 4. A *stop* (the user asks to
  stop) takes effect before any further submission: create `STOP` in the active `meta_m/`, which the launcher and
  harness check; running work finishes and is kept, and consolidation or final checks run only if the user then asks
  for them (remove `STOP` first). A *cancellation* (the user asks to cancel, or a run-wide limit the plan marks hard
  is reached) also stops running sessions and cancels jobs from their receipts, recording what was lost.
- **Checkpoint your own context.** At each phase boundary and after each meta-iteration review, update `CONTEXT.md`
  so a fresh session can resume. At a pause the plan already has, or once your context is large, also ask the user to
  compact or to resume in a fresh session: the orchestrator's context is re-read on every call.

## Supporting files
`<skill>` is this skill's folder; the phases say when to read each file.
- `assets/RUN_PLAN_light.md`, `assets/RUN_PLAN_heavy.md` (plan templates), `assets/CONTEXT.md` (resume index),
  `assets/checks.md` (checks, uncertainty, references), `assets/resources.md` (size, orchestration, context, budgets
  and limits, re-planning).
- `assets/heavy.md`: what only heavy searches need (harness additions, models and effort, usage log).
- `assets/detached.md` and `assets/COMMON_PROMPT.md`: detached workers and their brief.
- `assets/adapters/`: framework mechanics; read only those the run uses (`claude.md`, `codex.md`, `cluster.md`). For
  another framework, fill in the same fields with the user.
- `<skill>/scripts/`: `launch_workers.sh` (detached Claude Code or Codex workers), `worker_status.sh`,
  `usage_report.py` (token usage from local session logs) and `tests/run_tests.sh`; each documents itself in its
  header.
- References: the user may put papers, code or earlier results in the project's `references/` folder (never in this
  skill's folder, which every project shares).
