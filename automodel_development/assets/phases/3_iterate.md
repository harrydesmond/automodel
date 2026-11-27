---
name: iterate
entry: Phase 2 done and the search plan approved; status says Phase 3 (resume the active meta-iteration from its recorded state).
exit: The search has ended (stop rule, budget, M or the user), CONTEXT.md records the finalists and the primary candidate (or that no eligible candidate exists), and the user has confirmed the search is complete.
description: Third and main phase. Run M meta-iterations of S parallel agents making I sequential structural modifications each (in-session sub-agents, or detached workers for heavy searches), within the approved budget; review, report progress, re-plan and repeat.
---

# Phase 3 — Iterate

## Setup
1. **Diagnose before directing.** From the baseline (later: the last review), find where the error is and what
   limits it; a direction aimed at a failing region or gate is worth an agent only once you know what drives it.
2. **Working mode.** *Agents iterate* (default): each agent proposes, fits and evaluates its own attempts. *Batch
   proposals*: agents return candidates, the meta-agent fits them centrally; suits candidates that are strings or
   small edits scored by a cheap evaluator. Hybrids are fine.
3. **Orchestration** (`assets/resources.md` §2): in-session sub-agents, or detached workers for long evaluations
   (`assets/detached.md`).
4. **Plan.** Use the approved light plan or heavy part B; fill missing decisions using `RUN_PLAN.md` and
   `resources.md` §4 and `heavy.md` §2. Changes outside the delegated scope need approval (`SKILL.md`).

## Execution — for each meta-iteration m
### 1. Launch
Each agent writes only in `meta_m/agent_s/` and the shared `tools/`. It gets the brief of `assets/COMMON_PROMPT.md`
(detached workers as a file, in-session agents in their prompt) plus its seed (the baseline, or the seeds the last
review chose; with several targets, the incumbent for each), its direction, whether that is exploratory (Attempts,
below), its scope limits and the relevant `references/` material.

**Shared tools.** Agents keep reusable tools in `tools/`, one line each in `tools/INDEX.md`, and add one when an
analysis recurs; comparisons use the approved versions. An agent that finds a fault in a shared tool writes the fix
as a new version, uses it in its own attempts (saying so in their records), logs it in `tools/CHANGES.md` (fault,
evidence, test) and tells the orchestrator (detached workers: in `BLOCKER.md`); the others keep the approved version
until the review promotes the fix, unless the orchestrator finds their results wrong. Faults in anything that sets
scores, records or eligibility are reported, not edited: the orchestrator fixes them.

Before launching, update the `CONTEXT.md` status (active round, protocol version, remaining budget, next action) and
tell the user: m of M, the current best eligible score, the budget left, and when to expect the next update.

- **In-session:** launch the S sub-agents in parallel in one message, fresh for each meta-iteration. If a usage limit
  or another interruption stops them, check from the records what each was doing and resume it once the cause has
  cleared, harvesting pending jobs first (framework behaviour: its adapter).
- **Detached (heavy):** preflight each seed through the harness to reproduce its score; prepare launch inputs
  (with `job_state.sh` when evaluations are scheduler jobs, so sessions end at job boundaries; the token budget's soft
  guide in COMMON_PROMPT.md), launch and watch as in `detached.md`.

### 2. Attempts (each agent, I times)
One structural modification (or an explicitly assigned control), planned from the previous results, especially where
the model fits worst; screened cheaply first if full fits are expensive; implemented in `meta_m/agent_s/attempt_i/`;
fitted and scored through the harness. The agent continues from the better of the attempt and its parent; an
exploratory direction may continue from a worse but valid candidate within its budget, since some structures need an
inferior intermediate step, while the incumbent changes only under the decision rule.

**Batch proposals:** I is the number of rounds. Each round every agent writes `meta_m/agent_s/round_i.md` (the agreed
number of candidates in the harness's input format, one-line rationale each); the meta-agent validates and
de-duplicates them, fits them through the harness, and gives the next round the leaderboard, the failures and the
score cost of each unit of complexity. In-session, launch fresh sub-agents for each round with that summary as their
brief.

### 3. Review (meta-agent)
- **Validate.** Quarantine attempts without a validated result (crash, NaN, unfinished job) and keep earlier valid ones
  from the same agent. Harvest or cancel owned pending jobs. Compare only validated candidates.
- **Refit the shortlist** under comparable settings and from new starts (`checks.md`, convergence): an eligible fit
  can be a local optimum or sit on a validity bound. If search fits use a subsample, refit the shortlist on the full
  training data when the budget allows: subsample fits can understate a candidate and a direction.
- **Recombine** compatible parts of different agents' candidates (often the winners), checking imported helpers
  (`checks.md`, components); choose the next seeds, keeping a few valid candidates from distinct families for
  exploratory directions.
- **Verify** agents' claims that would shape the next brief (floors, infeasibility, "cannot help") with an
  independent check.
- **Check and promote tools:** verify each logged fix (reproduce the fault, run the tests), then promote or revert
  it; merge duplicated tools into the harness, with tests; list both in the next brief. Change harness code agents use
  only by testing a copy and swapping it in; a change that alters scores is a protocol change (new version, rescore).
- **Usage:** one line (light) or the usage log (heavy; `heavy.md` §3): proposals, screens and scored fits against
  the budget; heavy: tokens against the token budget, with the calls and context that drove them.
- **Re-orient** before choosing directions, in `review.md`: what the results, failures included, imply about the
  mechanism and which families are now less plausible; whether gains are structural or come from added flexibility
  (`checks.md`, uncertainty; matched parent refits and, where relevant, matched-complexity controls); remaining
  systematic residuals; whether the variables or representation should change; which experiment would be most
  informative next. Distinguish incremental refinements from fundamental changes.
- **Re-plan** (`resources.md` §5) and apply the stop rule. Use a fresh reviewer (new session or another framework)
  when the data, evaluator or protocol changed, a result is disputed, or the stakes warrant it.
- Write `meta_m/review.md` (results table, what worked and did not, decisions), then update the `CONTEXT.md` status
  (completed round, incumbent, budget, pending jobs with their receipts, next action) before any further launch.
  Then checkpoint your context (`SKILL.md`).

### 4. Report and continue
Send the user a short progress message: best eligible score and the attempt that produced it (with any reported-only
failures), what changed, budget spent and left (compute and, in heavy searches, tokens against the token budget), the
next plan. Then pause for review and guidance if the plan says so; otherwise continue unless the stop rule fires, M
or the budget is reached, or the next step needs approval. Stopping and cancelling follow `SKILL.md`; finished work
is kept and reported as such.

## Ending the search
How the search ended decides what follows (`SKILL.md`, ending a search). After a planned end, or after a stop once
the user asks for it, consolidate within the consolidation allocation: refit and recombine the front, on the full
training data if the search used a subsample, and diagnose the largest remaining errors, comparing them with the
target's own uncertainty to set priorities, not to change the target.

Then recommend the finalists and the primary candidate under the approved rule, with every gate value and trade-off
and, for any required gate no finalist meets, the options (continue work, change the requirement, or no eligible
result); `SKILL.md` (final selection and completion) says when the user chooses. A change to the rule or gates needs
approval, is a new protocol version, and the original result is still reported. Report the best score per
meta-iteration (plot), the changes that drove it, the usage, time and compute spent and the estimated cost of one
more meta-iteration, and ask the user whether the search is complete. Go on to Phase 4 only when they say so;
otherwise return to Phase 3 Setup (numbering on), with the primary candidate as the incumbent.

Once no owned work is still running (after a cancellation, at once), stop every server and background process the
search started and check that no owned job remains queued. Update `CONTEXT.md`: finalists, primary candidate and
their files, final search summary, why the search stopped.
