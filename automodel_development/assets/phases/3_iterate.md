---
name: iterate
entry: Phase 2 done and the search plan approved; status says Phase 3 (resume the active meta-iteration from its recorded state).
exit: The stop rule fires, the budget is spent, or the user ends the search; CONTEXT.md records the best eligible candidate, or that none exists.
description: Third and main phase. Run M meta-iterations of S parallel agents making I sequential structural modifications each (in-session sub-agents, or detached workers for heavy searches), within the approved budget; review, report progress, re-plan and repeat.
---

# Phase 3 — Iterate

## Setup
1. **Diagnose before directing.** From the baseline (later: the last review), find where the error is and what
   limits it; a direction aimed at a failing region or gate is worth an agent only once you know what drives it.
2. **Working mode.** *Agents iterate* (default): each agent proposes, fits and evaluates its own attempts. *Batch
   proposals*: agents return candidates, the meta-agent fits them centrally; suits candidates that are strings or
   small edits scored by a cheap evaluator. Hybrids are fine.
3. **Orchestration** (`assets/resources.md` §2): in-session sub-agents, or detached workers for long evaluations (`assets/detached.md`).
4. **Plan.** Use the approved light plan or heavy part B. Fill missing decisions using `RUN_PLAN.md` and
   `resources.md` §4–5; obtain approval for changes outside delegated scope or a material budget increase.

## Execution — for each meta-iteration m
### 1. Launch
Each agent writes only in `meta_m/agent_s/` and the shared `tools/`, and gets: its seed (the baseline, or the seeds the last review chose; with
several targets, the incumbent for each); its direction and scope limits; relevant `references/` material; the shared
harness and decision rule; its share of the evaluation budget; the attempt contract — each attempt ends with its
outcome recorded through the harness (result or recorded failure, short rationale) and no job pending; attempts change
structure unless the direction explicitly assigns a bounded convergence, recalibration or execution comparison
(record such gains as what they are, not as structural discoveries); the waiting and context rules (`resources.md` §3).
Agents keep reusable tools in a shared `tools/` folder with one line each in `tools/INDEX.md`, and check it before
writing a tool. An agent that finds a fault or limitation in a shared tool writes the fix as a new version, logs it in
`tools/CHANGES.md` (fault, evidence, test) and tells the orchestrator (detached workers: in `BLOCKER.md`); agents read `CHANGES.md` at the start of each
attempt. Faults in anything that sets scores, records or eligibility are reported, not edited: the orchestrator fixes
them.

Before launching, update the `CONTEXT.md` status (active round, protocol version, remaining budget, next action) and
tell the user: m of M, the current best eligible score, the budget left, and when to expect the next
update.

- **In-session:** launch the S sub-agents in parallel in one message, fresh for each meta-iteration. If a usage limit
  stops them (it stops all at once), resume each after the reset with an instruction to harvest pending jobs first.
  Sub-agents are sometimes refused writes of report-like files: have them return the text, and save it yourself.
- **Detached (heavy):** preflight each seed through the harness to reproduce its score; prepare launch inputs
  (with `job_state.sh` when evaluations are scheduler jobs, so sessions end at job boundaries; the token budget's soft
  guide in COMMON_PROMPT.md), launch and watch as in `detached.md`.

### 2. Attempts (each agent, I times)
Plan one structural modification (or the explicitly assigned control) from the previous results, especially where the model fits worst; screen cheaply
first if full fits are expensive (within the budget); implement it in `meta_m/agent_s/attempt_i/`; fit and score through
the harness; continue from the better of this attempt and its parent.

**Batch proposals:** I is the number of rounds. Each round every agent writes `meta_m/agent_s/round_i.md` (the agreed
number of candidates in the harness's input format, one-line rationale each); the meta-agent validates and
de-duplicates them, fits them through the harness, and gives the next round the leaderboard, the failures and the score
cost of each unit of complexity. In-session, launch fresh sub-agents for each round with that summary as their brief.

### 3. Review (meta-agent)
- **Validate.** Quarantine attempts without a validated result (crash, NaN, unfinished job) and keep earlier valid ones
  from the same agent. Harvest or cancel owned pending jobs. Compare only validated candidates.
- **Refit the shortlist** under comparable settings and from new starts (`checks.md`, convergence): an eligible fit
  can be a local optimum or sit on a validity bound. When search fits use a subsample,
  refit the shortlist on the full training data at boundaries the budget allows: subsample fits can understate both
  a candidate's performance and a direction's promise.
- **Recombine** compatible parts of different agents' candidates (often the winners), checking imported helpers
  (`checks.md`, components); choose the next seeds.
- **Verify** agents' claims that would shape the next brief (floors, infeasibility, "cannot help") with an
  independent check.
- **Check and promote tools:** verify each logged fix independently (reproduce the fault, run the tests) and keep or
  revert it, at once if other agents are using the tool; merge duplicated tools into the harness, with tests; list
  both in the next brief. Change harness code that agents use only by testing a copy and swapping it in; a change that
  alters scores is a protocol change (new version, rescore).
- **Usage**: one line (light) or the usage log (heavy; `resources.md` §6); proposals, screens and scored fits counted
  separately against the budget; tokens against the meta-iteration's token budget (a guide, never enforced), with the
  calls and context that drove them.
- **Re-orient** before choosing directions, in `review.md`: what the results, failures included, imply about the
  mechanism and which families are now less plausible; whether gains are structural or come from added flexibility
  (`TIPS.md`, uncertainty, for comparing candidates; use matched parent refits and, where relevant, matched-complexity controls); remaining systematic residuals; whether the variables or representation should
  change; which experiment would be most informative next. Distinguish incremental refinements from fundamental changes.
- **Re-plan** (`resources.md` §7) and apply the stop rule. Use a fresh reviewer (new session or another framework)
  when the data, evaluator or protocol changed, a result is disputed, or the stakes warrant it.
- Write `meta_m/review.md` (results table, what worked and did not, decisions), then update the `CONTEXT.md` status
  (completed round, incumbent, budget, pending jobs with their receipts, next action) before any further launch.
  Then checkpoint your context (`SKILL.md`).

### 4. Report and continue
Send the user a short progress message: best eligible score and the attempt that produced it (with any reported-only
failures), what changed, budget spent and left (compute, and tokens against the token budget), the next plan. Then pause for review and guidance if the plan says so;
otherwise continue unless the stop rule fires, M or the budget is reached, or the next step needs approval. A stop
request applies before any new submission; work already finished is kept and reported as such.

## Ending the search
Within the plan's reserve and any search budget left, consolidate (refit and recombine the front, on the full
training data if the search used a subsample), refit the references used in the final comparison with the same
convergence protocol (`checks.md`), so that gains are not measured against under-converged fits, and diagnose the largest remaining errors, comparing them with the
target's own uncertainty to set priorities, not to change the target. Then present the finalists to the user under the
approved rule with every gate value and trade-off and, for any required gate no finalist meets, the options (continue
work, change the requirement, or no eligible result), and ask the user to choose the finalists that go on to Phase 4;
a change to the rule or gates needs approval, is a new protocol
version, and the original result is still reported.

Present the best score per meta-iteration (plot), the changes that drove it, and the usage, time and compute spent, with
the estimated cost of one more meta-iteration. The user continues (back to Phase 3 Setup, numbering on) or ends the search.
Stop every server, queued job or background process the search started. Update `CONTEXT.md`: best eligible candidate
and its files, final search summary, why the search stopped.
