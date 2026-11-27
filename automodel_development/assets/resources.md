# Resources

## 1. Search size
Start light when fits are quick and total cost small: a compact plan, the minimal harness, simple execution and a brief
usage record. For substantial cost, or long or queued fits, the search is heavy: add `heavy.md` and read the
applicable adapter. Budget, latency and stakes are separate: many cheap fits need not require detached workers, and
one slow fit may need only a watcher. Reclassify at a boundary after measuring. Approval and pause defaults are in
`SKILL.md`.

## 2. Execution
Use the simplest execution the runtime supports. Record in `CONTEXT.md` the evaluator and where results persist;
worker capacity; permitted tools, write roots and network access; the completion mechanism; process lifetime;
recovery and cancellation of owned work; and the model, effort and usage controls available. Assume nothing the runtime
does not expose.
- **In-session:** independent briefs, run in parallel within capacity, reviewed on completion; fresh agents each
  meta-iteration where supported.
- **Detached:** for long work, `detached.md` and the applicable adapter. The supplied Linux launcher covers the
  runtimes that have adapters; another runtime needs a compatible adapter or project launcher.
- **Sequential:** without delegation, work the S directions in turn in this session, each with its own notes and
  records and one shared budget, then review as usual. Record that they shared context and were not independent.

## 3. Waiting and context (worker briefs)
Measure calls, context, cached and uncached input, output, latency
and useful work where reported; the defaults below are starting points, revised after the pilot and each review.
- Do not poll from a model session where a non-model wait exists. Prefer, in order: sessions that end at job
  boundaries, completion notifications, watchers that do not wake the model, blocking waits; otherwise check rarely,
  at a cadence suited to the job. Submit and collect each batch in one cycle with one line per candidate.
- Keep bulky outputs in files; print compact summaries or tails (about 40 lines); change large files with scripts or
  targeted edits; reuse scripts; read others' work through summaries; generate tables from records.
- End long sessions at useful boundaries (starting guide about 50 model calls where countable; detached workers'
  `AM_SESSION_CALLS` is a prompt guide, not an enforced cap). Detached hand-offs keep `STATE.md` and pending receipts;
  in-session agents update their notes before returning. Notes give the best record IDs, assumptions, what worked,
  unresolved failures and next hypotheses. Where calls cannot be counted or sessions replaced, checkpoint at natural
  boundaries.
- Worker defaults only: attempt plan ≤ 150 words, rationale ≤ 200, final reply ≤ 3 lines, summary about 300 words
  (longer if a diagnosis needs it) with record IDs, best structure, failure causes, reusable components and next
  step.
- Stay within the direction and the budget: no unplanned side audits or score-only reruns. If reproduction, provenance
  or scoring contradicts the plan, stop the affected comparisons, report the evidence briefly (detached workers:
  `BLOCKER.md`) and run only the smallest diagnostic needed.
- Before a session ends, record its results or leave `.job` receipts saying how to harvest them.

## 4. Budget, limits and estimates
The harness charges the ledger (`phases/1_setup.md` §6) at submission, failures and restarts included. Each limit in
the plan is an estimate (reported and revised), a submission cutoff (new work refused, admitted work finishes) or an
execution limit (owned work stopped at the limit, checkpointed if possible). Reserve outstanding commitments before
admitting work. An execution limit needs a mechanism covering every affected job, not only the launcher: deadlines set
from the remaining allowance, or a controller that cancels from receipts. Without one, describe the limit as a cutoff
or an estimate, not a hard deadline.

Without a mechanism that enforces it (a provider quota, say, which can exist without readable usage), a usage
allowance is controlled only through the amount of work queued, chosen conservatively from the user's readings around
the pilot; this is an estimate, not a strict bound, since retries and resumptions after resets can draw more. Explain
what can be enforced before approval. Do not convert tokens into money or allowance without the user's prices or
readings.

Estimate representative attempts plus setup, review, finalization and contingency; state unknowns; update after the
first meta-iteration. Usage ≈ S × I × usage per attempt + orchestration; wall time from the actual execution schedule
(sequential directions add up; limited capacity runs in waves), including queueing, noticing and review; compute ≈
fits × cost. Heavy: estimate tokens from the measured pilot or the last meta-iteration (calls × typical context),
give workers a soft guide and report observed use; never interrupt an agent for exceeding an estimate. Without
telemetry, use fit counts, elapsed time and available costs (`heavy.md` §3).

## 5. Re-plan at boundaries
Use results and measured costs to adjust directions, seeds, S, I, allocations and session guides. Retire directions
whose premise the evidence contradicts or that another component blocks, not every null round; keep a bounded share
for distinct untested hypotheses. Reassess the number of directions each time and merge the best lineages where they
have become compatible or converge; keep separate directions where diversity is informative. Diagnose wasted fits
before changing allocations, and persistent gate failures before proposing continued work, a changed requirement or
no eligible result. Record the reasons, report the next plan and seek approval for changes outside the delegated
authority.
