# Checklist for automodel

Progress tracker — copy to project root and update as you complete each step.

## Phase 1 — Setup
- [ ] Search size (light / heavy) and the user's limits recorded; heavy: framework tiers and mechanics confirmed
- [ ] Goal, data, metrics, and optimization routine reviewed with user
- [ ] Selection score agreed with user; splits and external check set accordingly
- [ ] Checks adopted / N/A recorded
- [ ] `RUN_PLAN.md` part A approved by the user
- [ ] `CONTEXT.md` created; suggest compacting if this phase left bulky output

## Phase 2 — Baseline Model
- [ ] Baseline and shared attempt harness implemented; end-to-end pipeline verified by a sub-agent; cost calibration recorded
- [ ] References scored at default settings (deep refits for incumbents only)
- [ ] `CONTEXT.md` updated with baseline metrics; suggest compacting if this phase left bulky output

## Phase 3 — Iterate
- [ ] `RUN_PLAN.md` part B filled (mode, orchestration, M or stop rule, S, I, directions, models, estimate, pauses) and the whole plan approved
- [ ] Meta-iteration 1 reviewed (refits, recombination, usage); next S, I, R re-planned; `CONTEXT.md` updated; progress message sent (paused if the plan says so)
- [ ] *(repeat for each subsequent meta-iteration)*
- [ ] Progress reviewed with user; servers and jobs started by the search stopped; `CONTEXT.md` updated with best model pointer; suggest compacting if this phase left bulky output

## Phase 4 — Finalize
- [ ] Models, decision rule and claims pre-registered
- [ ] Best model evaluated against the external check agreed in Phase 1 (or re-verified, if none was agreed)
- [ ] Final decision, test metrics, and limitations recorded in `CONTEXT.md`
