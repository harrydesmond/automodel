# Testing automodel-development

`automodel_development/` is the development version of the automodel skill. It replaces `automodel/` and adds:
search sizing (light searches stay simple; heavy searches get model tiers, usage logging and detached "hybrid"
workers), waiting and context rules, re-planning of S/I/models at every meta-iteration, a shared attempt harness and
a menu of checks (`assets/checks.md`).

## Install
Copy or link the folder as its own skill (both versions can coexist; remove `automodel` if you want only this one):
    ln -s <repo>/automodel_development ~/.claude/skills/automodel-development     # Claude Code
    ln -s <repo>/automodel_development ~/.codex/skills/automodel-development      # Codex
Start a session in your project and say e.g. "use automodel-development to find a better model for …".

## Notes
- Heavy searches launch unattended worker sessions (`scripts/launch_workers.sh`) with permission prompts off; the skill
  asks before doing so. Light searches do not.
- `scripts/usage_report.py claude|codex --cwd <project> --since <time>` summarises token usage from session logs.

## What to send back
Process records only, no data: `CONTEXT.md`, `CHECKLIST.md`, the `meta_*/agent_*/summary.md` and `evaluation.md` files
(or the run folder zipped without data), the `usage_report.py` output, and three short answers:
1. What did you have to add or work around?
2. What went wrong or had to be redone, and when was it noticed?
3. What should the skill have asked or suggested that it did not?
