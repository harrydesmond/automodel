# Testing automodel-development

`automodel_development/` is the development version of the automodel skill. It replaces `automodel/` and adds:
search sizing (light searches stay simple; heavy searches get usage accounting and detached "hybrid"
workers), one approved run plan (`RUN_PLAN.md`) with no silent defaults, an enforced evaluation budget, a shared
attempt harness with per-fit records and evaluator tests, progress reports and optional pauses, and a menu of checks
(`assets/checks.md`). Revised after an external audit (2026-11-03).

## Install
Copy or link the folder as its own skill (both versions can coexist; remove `automodel` if you want only this one):
    ln -s <repo>/automodel_development ~/.claude/skills/automodel-development     # Claude Code
    ln -s <repo>/automodel_development ~/.codex/skills/automodel-development      # Codex
Start a session in your project and say e.g. "use automodel-development to find a better model for …".

## Notes
- Heavy searches can launch unattended worker sessions (`scripts/launch_workers.sh`) with permissions you approve
  (`AM_CLAUDE_FLAGS` / `AM_CODEX_FLAGS`); light searches run inside your session.
- `bash scripts/tests/run_tests.sh` checks the launcher, status and usage scripts with fake CLIs (no model calls).
- `scripts/usage_report.py claude|codex --cwd <project> --since <time>` summarises token usage from session logs.

## What to send back
Process records only, no data: `CONTEXT.md`, `CHECKLIST.md`, the `meta_*/agent_*/summary.md` and `evaluation.md` files
(or the run folder zipped without data), the `usage_report.py` output, and three short answers:
1. What did you have to add or work around?
2. What went wrong or had to be redone, and when was it noticed?
3. What should the skill have asked or suggested that it did not?
