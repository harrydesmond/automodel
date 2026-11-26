---
tags: [skill-creator, dry-run]
max_turns: 40
timeout_seconds: 1200
allowed_tools: [Read, Glob, Grep, Skill, Write]
---

My laptop rebooted on Saturday night and I've only just noticed. Resume the automodel-development run in this folder.

Stopping point: the first action that would start new work (a launch or submission) or the first point where you need the user's decision; include everything you would check and do before it.

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

Input files: CONTEXT.md, harness/README.md, meta_1/review.md, meta_2/review.md, meta_3/agent_1/attempt_1/card.md, meta_3/agent_1/attempt_2/card.md, meta_3/agent_1/attempt_3/card.md, meta_3/agent_1/attempt_4/card.md, meta_3/agent_1/attempt_5/card.md, meta_3/agent_1/DIRECTION.md, meta_3/agent_1/.summary.done, meta_3/agent_1/summary.md, meta_3/agent_2/attempt_1/card.md, meta_3/agent_2/attempt_2/card.md, meta_3/agent_2/attempt_3/card.md, meta_3/agent_2/attempt_4/.job, meta_3/agent_2/attempt_4/STATE.md, meta_3/agent_2/DIRECTION.md, meta_3/agent_3/attempt_1/card.md, meta_3/agent_3/attempt_2/card.md, meta_3/agent_3/attempt_3/card.md, meta_3/agent_3/attempt_4/plan.md, meta_3/agent_3/DIRECTION.md, meta_3/agents.conf, meta_3/COMMON_PROMPT.md, meta_3/launch.log, meta_3/launch_manifest.jsonl, meta_3/.lock/groups, meta_3/.lock/launcher, RUN_PLAN.md
