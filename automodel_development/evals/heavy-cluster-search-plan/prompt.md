---
tags: [skill-creator, dry-run]
max_turns: 40
timeout_seconds: 1200
allowed_tools: [Read, Glob, Grep, Skill, Write]
---

Use automodel-development on my reaction–diffusion project (this folder; README.md describes it). The logistic reaction term leaves structured residuals near the front, and I want a search for better reaction terms f(u), and possibly a nonlinear diffusion D(u). Each fit is a ~20 min Slurm job on our cluster (glamdring; sbatch from the login node, via fit/submit_fit.sh). I'd like it to run with detached workers over the weekend while I'm away (Friday evening to Monday morning), using no more than about half my weekly Claude allowance. The model has to keep u between 0 and 1. Framework: Claude Code.

Stopping point: the message asking the user to approve the setup part of the plan. Then add a section outlining, as the skill directs, what you would do from there up to and including the first worker launch (what is tested, what is approved and when, how workers are launched and with which permissions, and what happens during the weekend).

DRY RUN: do not execute anything. You may read any file (the skill's and the project's), but do not run code or
shell commands, time evaluations, launch agents, sub-agents or workers, or create or change files in the project.
Wherever the skill tells you to do, run, ask or write something, record it instead in `walkthrough.md`:

1. **Steps**, in order. For each: what you do, the skill file and section that tells you to, and the exact command
   you would run or file you would write.
2. **Messages to the user**, verbatim, at the point you would send each one.
3. **Files** you would create or fill (e.g. RUN_PLAN.md, CONTEXT.md), in full as far as they can be filled without
   running anything; mark values that depend on a run as `<from run: ...>`.
4. When you would wait for the user, assume the replies given in the task if any; otherwise assume the user accepts
   your proposals, say so, and continue until the stopping point the task names.
5. A final section **Unclear or conflicting instructions**: every place where the skill was ambiguous,
   contradictory, missing something you needed, or made you guess, with file and section. Write "none" if none.

Input files: data/profiles.txt, fit/fit_one.py, fit/submit_fit.sh, model/rd.py, README.md
