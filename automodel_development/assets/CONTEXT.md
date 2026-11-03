# <Project name> — automodel context

> Compact resume index, not a history. Decisions live in `RUN_PLAN.md`; each meta-iteration's details in
> `meta_m/review.md`. A fresh session reads this file, `RUN_PLAN.md` and the current phase recipe, then resumes.

## Status
- **Phase / step:** <e.g. 3 / review of meta_2>
- **Active meta-iteration:** <m, state: planned / running / reviewing / done>; last completed: <m>
- **Plan and protocol:** `RUN_PLAN.md` v<n> (approved <date>); decision-rule version <v>
- **Best eligible candidate:** `<path>` — <score>; reported-only failures: <…>
- **Budget:** <fits / wall time / compute used of cap>
- **Pending jobs and processes:** <IDs, owner, how to harvest or cancel; "none">
- **Next action:** <…>

## Project facts
- **Data:** <files, variables, units (decisions on splits and reserved data: RUN_PLAN.md)>
- **Harness:** <commands to fit/score a candidate; record location; validator; budget counter; tests>
- **Optimizer:** <method, restarts, seeds, stop criterion>
- **Baseline and references:** <form, scores, runtime, memory>
- **Calibration:** <time and compute per evaluation; usage per attempt if measured>
- **Execution:** <how to run locally / on the cluster / workers; framework mechanics confirmed>

## Meta-iterations
| m | best eligible score | from | review |
|---|---|---|---|
| 0 | <baseline> | baseline | — |

## Final outcome (Phase 4)
- **Decision:** <accept / exploratory result / no useful improvement / do not use>
- **Selected model and entry point:** <…>
- **Metrics:** <selection score; external check; runtime; memory>
- **Claims and what they were checked on; main limitations:** <…>
