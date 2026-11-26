# rd_terms — automodel context

> Compact resume index, not a history. Decisions live in `RUN_PLAN.md`; each meta-iteration's details in
> `meta_m/review.md`. A fresh session reads this file, `RUN_PLAN.md` and the current phase recipe, then resumes.

## Status
- **Phase / step:** 3 / meta_3 running (detached workers)
- **Active meta-iteration:** 3, running (launched 2026-11-20 19:12 UTC); last completed: 2
- **Plan and protocol:** `RUN_PLAN.md` v2 (approved 2026-11-18); decision-rule version 1
- **Best eligible candidate:** `meta_2/agent_1/attempt_3` — val RMSE 0.0213 (baseline 0.0347); reported-only failures: none
- **Budget:** 212 of 300 scored fits; 41 of 60 h wall time; 3,400 of 6,000 core-h
- **Pending jobs and processes:** launcher `meta_3/.lock`; Slurm jobs listed in each attempt's `.job`
- **Next action:** when `worker_status.sh meta_3 --wait` returns, review meta_3

## Project facts
- **Data:** 40 profiles (8 experiments x 5 times); train = experiments 1–6, validation = 7–8; reserved: none (exploratory)
- **Harness:** `python3 harness/submit.py <candidate.py>` (submits, blocks ≤ 9.5 min, prints state);
  `python3 harness/harvest.py <attempt_dir>`; `python3 harness/collect.py` builds tables from `records/`;
  `harness/done_attempt.sh <attempt_dir>`; `harness/job_state.sh <attempt_dir>`; budget counter `harness/budget.json`
- **Optimizer:** scipy least_squares, 8 starts, seeds 0–7, ftol 1e-8
- **Baseline and references:** Fisher–KPP 0.0347; Nagumo (bistable) 0.0298
- **Calibration:** one fit ≈ 20 min on 16 cores (5.3 core-h); ~110k tokens per attempt (meta_1 log)
- **Execution:** Glamdring (`glam`, sbatch via `fit/submit_fit.sh`); launcher runs locally (setsid nohup) with
  `AM_CLAUDE_FLAGS="--permission-mode acceptEdits --allowedTools Bash(python3:*) Bash(glam:*)"`

## Meta-iterations
| m | best eligible score | from | review |
|---|---|---|---|
| 0 | 0.0347 | baseline | — |
| 1 | 0.0262 | meta_1/agent_2/attempt_4 | meta_1/review.md |
| 2 | 0.0213 | meta_2/agent_1/attempt_3 | meta_2/review.md |
