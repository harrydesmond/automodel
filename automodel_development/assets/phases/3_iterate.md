---
name: iterate
entry: Phase 2 done and the search plan approved; status says Phase 3 (resume the active meta-iteration from its recorded state).
exit: The search has ended (stop rule, budget, M or the user), CONTEXT.md records the finalists and the primary candidate (or that no eligible candidate exists), and the user has confirmed the search is complete.
description: Third and main phase. Run M meta-iterations of S directions with I attempts or proposal rounds each, using the approved execution mode; review, report and re-plan within budget.
---

# Phase 3 — Iterate

## Setup
Diagnose the baseline or the last review: where the error is, what limits it and which hypotheses are informative; a
direction aimed at a failing region or gate is worth an agent only once you know what drives it. Choose agents
iterating (default) or batch proposals (for cheap, compact candidates fitted centrally); hybrids are allowed. Choose
the execution mode (`resources.md` §2; `detached.md` if applicable). Use the approved light plan or heavy part B,
filling missing decisions from the plan and `resources.md` (heavy model options: `heavy.md` §2).

## Each meta-iteration m
### 1. Launch
Checkpoint the active meta-iteration, protocol version, incumbent, remaining budget and next action in `CONTEXT.md`.
Before launching, report m of M, the best eligible score, the remaining allowance and when the next update is due.

Give each direction its seed (the baseline or the review's choice; the incumbent per target where there are several),
its hypothesis, whether it is exploratory, its references and scope, and the brief of `assets/COMMON_PROMPT.md` (a file
for detached workers, the prompt for in-session agents). It writes only in its own `meta_m/agent_s/` and the shared
`tools/`.

**Shared tools.** Add one when reuse appears and index it in `tools/INDEX.md`; comparisons use the approved versions.
A fix to a shared tool is a new version; its author labels its own use in the records, logs fault, evidence and test
in `tools/CHANGES.md` and notifies the orchestrator (detached: `BLOCKER.md`). Others keep the approved version until
the review, unless the orchestrator finds their results wrong. Faults in scoring, eligibility or record machinery are
reported, never edited by agents: the orchestrator fixes them.

Launch with the approved capacity and mode: native parallel agents, sequential directions (`resources.md` §2), or
detached workers after reproducing each seed through the harness, with the job-state hook for scheduler jobs and a
soft usage guide where available (`detached.md`). After an interruption, inspect the records, reconcile and harvest
jobs, and resume through the runtime's mechanism. Use fresh native agents each meta-iteration where supported.

### 2. Attempts (I per direction)
Plan one structural modification, or an assigned bounded control, from the previous results, especially where the
model fits worst; screen cheaply if fits are expensive; implement it in `attempt_i/`, then fit and score through the
harness. Record the outcome and rationale. An attempt is complete only when its required results or failures are
recorded and none of its jobs is pending; an intermediate hand-off leaves recoverable receipts and state. Continue from
the better of parent and attempt, or, in an exploratory direction, from a worse but valid candidate within its budget;
the incumbent changes only under the rule. Label convergence, recalibration and execution gains as controls, not
structural discoveries.

Batch mode: I proposal rounds; each direction supplies the agreed number of candidates with one-line rationales in
`round_i.md` or equivalent. Validate and de-duplicate them, fit them centrally through the harness, and return the
leaderboard, failures and, where defined, the score cost of complexity. Use fresh agents each round if available.

### 3. Review
- Quarantine invalid or incomplete attempts and keep earlier valid records; harvest or cancel owned pending work as
  the ending in force allows; compare validated candidates only.
- Within the authorised allowance, refit the shortlist from its optima and new starts with comparable settings
  (`checks.md`, convergence), and, if search fits used a subsample, refit the shortlist on the full training data
  when the budget allows. Recombine compatible components after checking their interfaces; choose seeds, keeping
  distinct valid families for exploration.
- Independently verify consequential claims (floors, infeasibility, null directions). Reproduce and test logged tool
  fixes, then promote or revert them; merge duplicated tools into the harness, with tests, and tell the next workers.
  Test harness changes on a copy before swapping them in; changed scores need a new protocol version and comparable
  rescores.
- Record proposals, screens and fits against the allowance, and a usage summary (heavy: `heavy.md` §3).
- Re-orient in `review.md`: what the results, failures included, imply about the mechanism and which families are now
  less plausible; whether gains are structural or come from added flexibility (`checks.md`, uncertainty; matched parent
  refits and complexity controls where relevant); remaining systematic residuals; whether the variables or
  representation should change; the most informative next work. Distinguish incremental refinements from fundamental
  changes. Diagnose wasted fits.
- Re-plan (`resources.md` §5) and apply the stop rule. Use a fresh reviewer when the data, evaluator or protocol
  changed, a result is disputed or the stakes are high, if one is available; otherwise disclose that.
- Write `meta_m/review.md` (results, lessons, decisions). Update `CONTEXT.md` (completed meta-iteration, incumbent,
  budget, pending receipts, next action) before another launch, and checkpoint (`SKILL.md`).

### 4. Report and continue
Report the eligible incumbent and its attempt, diagnostic failures, what changed, budget spent and remaining, and the
next plan (heavy: usage against the estimate where available). Pause as agreed; otherwise continue within the delegated
authority until the stop rule, M or the allocation's end. Stopping and cancelling follow `SKILL.md`: keep completed
work, and collect or record pending receipts.

## Ending the search
After a planned end, or a stop once the user authorises consolidation, spend the consolidation allocation on refits
and recombination (on the full training data if search fits used a subsample) and on diagnosing residuals against the
target's own uncertainty, to set priorities, not to change the target. Respect the latest stop and the protected
final-check allocation.

Recommend the finalists and the primary candidate under the rule, with gate values, trade-offs, and the options if no
finalist is eligible (continue work, change the requirement, or no eligible result). Changes to gates or the rule
need approval, a new version and rescores; the original result is still reported. Report the score progression
(plot), structural gains, usage, time and compute, and the cost of another meta-iteration. Record "awaiting
completion decision" and wait for the user: go to Phase 4 only on explicit confirmation that the search is complete,
and return to Setup (numbering on, the primary candidate as incumbent) only on an explicit request to continue. Stop
owned processes once their work has ended, reconcile queued jobs and record unresolved work. Update `CONTEXT.md`:
finalists and primary candidate (or none), files, budget and why the search ended.
