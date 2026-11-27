---
name: automodel-development
description: Development version of automodel: discovers a better model structure from data (feature transformations, equation terms in ODEs or PDEs, neural-network layer compositions) with a meta-agent directing parallel sub-agents or detached worker sessions, from quick in-session searches to multi-day cluster runs. Only invoked when the user explicitly asks for /automodel-development, "use automodel-development" or the development version of automodel, including resuming such a run. Requests that name plain automodel, or ask for a model-structure search without naming this skill, do not invoke it.
license: Apache-2.0
---

# automodel
Search model structures (features, equation terms, architectures), not merely parameter values, with a meta-agent
directing several search directions in parallel or in turn.

| Phase | Recipe under `assets/phases/` | Done when |
|---|---|---|
| Setup | `1_setup.md` | Plan approved (heavy: setup part); `CONTEXT.md` created |
| Baseline | `2_baseline_model.md` | Harness and pilot validated; baseline and references scored; calibration recorded (heavy: search plan approved) |
| Iterate | `3_iterate.md` | The user confirms the search is complete |
| Finalize | `4_finalize.md` | Outcome recorded, including no eligible result |

The method needs an evaluator it can run and durable records of the results; directions run in parallel where the
runtime can delegate work, otherwise in turn. The supplied detached-worker launcher needs Bash with GNU tools and the
Claude Code or Codex CLI; other runtimes need the capability record of `resources.md` §2 and one real pilot.

## Start or resume
If no `CONTEXT.md` exists, start Setup. Otherwise read its status and `RUN_PLAN.md`; validate the referenced
artifacts and resume the first incomplete step. A directory's presence is not completion. Where status and disk
disagree, trust the disk: reconcile jobs from their receipts, and reclaim a stale launcher lock only once no owned
launcher or worker process survives. Before restarting, report the discrepancies, what will restart and what it may
still spend. If the phase is unclear, `bash <skill>/scripts/read_phases.sh` prints each phase's entry and exit
conditions. Load only the current phase and the supporting files it names.

## Working with the user
This section is the one authority on approval, selection, completion, stopping and checkpoints.
- **Approval.** `RUN_PLAN.md` is authoritative (from `assets/RUN_PLAN_light.md` or `assets/RUN_PLAN_heavy.md`). Mark
  decisions [user chose], [delegated] or [proposed]; reuse explicit choices and standing delegation. A general "your
  choice" does not delegate a gate or requirement that changes which known references are eligible: propose it and
  show its effect. Resolve every [proposed] item that changes the objective, the permitted work or the budget before
  approval; a light search approves one plan, a heavy one approves setup and then the calibrated search. Ask again
  only for a changed objective or protocol, work outside the delegated authority, a material budget increase, an
  unresolved final trade-off, or completion. A skipped or partly answered question stays open; never settle it
  unseen.
- **Selection and completion.** Recommend the finalists and the primary candidate under the rule. A clear winner
  becomes the primary candidate without asking; unresolved trade-offs, unmet requirements or changed claims go to the
  user. Heavy searches report the finalists regardless. Phase 4 starts only on the user's explicit confirmation that
  the search is complete; until then record "awaiting completion decision" and continue only on request, within the
  approved allowance.
- **Progress.** Report before launches, during long work and after each meta-iteration; pause between them as agreed
  (default: light continues, heavy pauses).
- **Endings.** A planned end (stop rule, M, or search allocation spent) opens consolidation; Phase 4 opens the
  protected final-check allocation. A stop (the user asks to stop) takes effect before any further submission: create
  `STOP` in the active `meta_m/` (the launcher and harness check it). Admitted work finishes; collect it through the
  harness from its receipts, or record the receipts as pending. Consolidation or final checks after a stop need the
  user's go-ahead; then remove `STOP` first. A cancellation (user request, or an execution limit, `resources.md` §4)
  also ends owned sessions and cancels owned jobs from their receipts; record losses and verify cleanup. A submission
  cutoff cancels no admitted work.
- **Checkpoint.** Update `CONTEXT.md` at phase and review boundaries. Refresh or compact your context when it grows
  large, with the runtime's mechanism, asking the user only where they must act.

## Supporting material
`<skill>` is this folder. Follow phase references to the plan and context templates, `checks.md`, `resources.md`,
`heavy.md`, `COMMON_PROMPT.md`, `detached.md` and the applicable `assets/adapters/`. The scripts implement the
supplied launcher and usage reports (the adapters say for which runtimes); other runtimes may use equivalent
mechanisms. Domain references belong in the project's `references/`, never in this shared folder.
