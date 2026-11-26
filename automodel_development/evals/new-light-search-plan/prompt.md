---
tags: [skill-creator, dry-run]
max_turns: 40
timeout_seconds: 1200
allowed_tools: [Read, Glob, Grep, Skill, Write]
---

I've got a 30-day hospital readmission model in this folder: a logistic regression in baseline.py on data/readmit.csv (about 48k admissions, one row per admission). It works, but I suspect the features aren't in the right form: age, length of stay and the lab values probably need transforming or interacting. Use automodel-development to find a better feature structure. It has to stay a logistic regression the clinicians can read, and predicted risk must go up with the number of prior admissions. Metric: your choice. A fit takes a couple of seconds on my laptop.

Stopping point: the message asking the user to approve the run plan (the end of the setup phase).

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

Input files: baseline.py, data/readmit.csv, README.md
