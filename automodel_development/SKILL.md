---
name: automodel-development
description: Guides the user in discovering a better model structure (e.g. from feature transformations in logistic regression to equation terms within PDEs to neural network layer compositions) out of data. Use when the user asks to create or improve an existing model. Uses an iterative meta/inner agent loop to explore structural model modifications in parallel, sized from quick in-session searches to long runs on detached worker sessions.
license: Apache-2.0
---

# automodel
A structured guide to discovering models from data with agents.
Focuses on the structure of the model (be it equation terms or neural network layers) rather than just parameter values, using an iterative meta/inner agent loop to explore structural modifications in parallel. Applies to a wide range of tasks, from simple regression to complex physical systems, from automotive to pharmacology.

## Phases

This skill is organized into four sequential phases, each with a detailed recipe in `assets/phases/`:

| Phase | Recipe | Entry signal |
|---|---|---|
| **1 — Setup** | `assets/phases/1_setup.md` | No `CONTEXT.md` artifact in project root |
| **2 — Baseline Model** | `assets/phases/2_baseline_model.md` | `CONTEXT.md` exists; Some prep work done; |
| **3 — Iterate** | `assets/phases/3_iterate.md` | End-to-end pipeline verified for baseline model (resume from the highest existing `meta_*/` directory) |
| **4 — Finalize** | `assets/phases/4_finalize.md` | User satisfied with the selection score; `CONTEXT.md` points to best model |

Each phase updates `CONTEXT.md`. Use the resulting artifacts as re-entry signals when resuming.

## How to start

1. Copy `assets/CHECKLIST.md` to the project root (if not already present) and update it as you go.
2. Detect the current phase using the entry signals above. If a checklist with partial progress is already present, ask the user whether to resume.
3. Read **only the frontmatter** of all phase files to confirm which one applies — do not load the full recipes yet:
   ```bash
   # bash / zsh
   bash scripts/read_phases.sh
   ```
   ```powershell
   # PowerShell
   pwsh scripts/read_phases.ps1
   ```
   The frontmatter `entry`, `exit`, and `description` fields are sufficient to identify the applicable phase without loading full recipes into context.
4. Once the applicable phase is confirmed, load and follow its full recipe (`assets/phases/<N>_<name>.md`).

## Working with the user

- **Approve before running.** All decisions are collected in `RUN_PLAN.md` (template `assets/RUN_PLAN.md`), each
  marked as the user's choice or your assumption. The user approves its setup part at the end of Phase 1 and the
  whole plan before the first search launch; nothing costly runs before approval.
- **No silent defaults.** If a question is skipped, interrupted or only partly answered, ask the open parts again or
  list them in the plan as `[assumed: …]` for approval. Do not settle them yourself without showing it.
- **Progress is visible.** After every meta-iteration send a short progress message; pause for the user's review if
  the plan says so (default: light searches continue, heavy searches pause).

## Search size

Phase 1 classifies the search as **light** (evaluations of seconds; sub-agents in the session, minimal resource
planning) or **heavy** (evaluations of minutes to hours, or a large share of the user's allowance; model tiers, a usage
log, and *hybrid* orchestration: the session's meta-agent launches detached worker sessions, one fresh session per
attempt, and reviews their results without supervising attempts). See `assets/resources.md` §1.

## Supporting files

- `assets/resources.md`: search size, orchestration, waiting and context rules, models and effort, cost estimates,
  usage log, re-planning between meta-iterations.
- `assets/frameworks.md`: per-framework mechanics (Claude Code, Codex, other): models and effort, sub-agents, detached
  workers, wait primitives, usage signals.
- `assets/checks.md`: a menu of checks per phase; each phase picks what fits by cost and stakes.
- `scripts/launch_workers.sh`, `scripts/worker_status.sh`: hybrid workers and their one-screen status;
  `scripts/usage_report.py`: per-session usage from the frameworks' own logs. All scripts live in this skill's folder
  (`<skill>/scripts/…`) and are run from the project root.

## References

The user may place relevant papers, code snippets, or other resources in a `references/` folder in the project root (not in this skill's folder, which is shared by all projects) — check them only when prompted to do so within a particular phase, and refer back / review with the user as needed.

## Optional tips

`TIPS.md` collects optional, use-case-dependent practices (metric uncertainty, optimizer-noise controls, a leaderboard, trivial baselines) kept out of the core recipes because their relevance varies by domain. Consult it — or fold relevant items into your fork — as needed.
