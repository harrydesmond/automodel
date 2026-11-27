# Resources: size, orchestration, waiting, models, budget and usage

`<skill>` is this skill's folder; its scripts are run from the project root.

## 1. Search size
| | light | heavy |
|---|---|---|
| when | evaluations of seconds; the search is a small share of the user's allowance | evaluations of minutes to hours or queued, or usage that could approach the allowance |
| plan | compact plan, approved once | part A (setup), then part B after calibration |
| harness | records, budget and stop (`phases/2_baseline_model.md` §1) | also the additions of `heavy.md` §1 |
| orchestration | in-session sub-agents | detached workers (`detached.md`) when evaluations are long; otherwise in-session |
| models | the session's model, or one model for all agents | options per direction (`heavy.md` §2) |
| usage record | one line per meta-iteration | usage log (`heavy.md` §3) |
| between meta-iterations | progress message, continue | progress message, pause for review |

Keep budget, evaluation latency and stakes apart: a million cheap evaluations can be costly without needing detached
workers, and one slow evaluation may need a watcher but no model planning. If unsure, start light and switch at a
boundary when measurements say so.

## 2. Orchestration
**In-session sub-agents.** The meta-agent launches the agents with the framework's sub-agent tool and reviews when
their completion notices arrive. An agent re-reads its growing context at every wake-up, so give each agent one
session per meta-iteration and fresh agents for the next, briefed by the review.

**Detached workers (default for long evaluations).** Fresh non-interactive sessions run by
`<skill>/scripts/launch_workers.sh` (Claude Code and Codex; another CLI needs an adapter or a project launcher with
the same contract), while the meta-agent stays in the user's session and does not supervise attempts: `detached.md`.
Without parallel sub-agents or a supported non-interactive mode, run the agents sequentially and record it.

## 3. Waiting and context (for prompts and COMMON_PROMPT.md)
Cost grows with model calls × context per call, so long sessions dominate. Measure it (uncached input, cache writes,
cache reads and output, against latency and useful work) rather than assume it; the defaults below are starting
points, revised from the pilot and each usage log.
- Do not poll from a model session. Prefer phase sessions (`detached.md`), then completion notifications, then a
  watcher that polls without waking the model, then a harness wait command as long as the framework allows (adapter).
- Keep bulky output out of context: analysis in short scripts that print compact summaries; long outputs to files,
  printing tails (≤ ~40 lines); large files changed by scripts or targeted edits; others' work read through summaries
  and exchange notes; tables from the harness's records and card. Edit and reuse scripts rather than write variants.
- One model call per evaluation batch: submit blocks until results arrive (or the wait limit) and prints one line per
  candidate; under phase sessions, submit, write `STATE.md` and end instead.
- End a session after about N model calls, at a job boundary where possible (starting default N = 50, revised from
  the pilot and the usage logs; detached workers get it as `AM_SESSION_CALLS`): a detached worker writes
  `attempt_i/STATE.md` and ends (the launcher resumes it without spending a retry); an in-session agent updates
  `notes.md`, returns and is relaunched fresh. Notes carry the current best with its record IDs, what worked,
  assumptions, unresolved failures and next hypotheses: a fresh session loses what they leave out.
- Worker outputs (not the run plan or the final report): attempt plan ≤ 150 words, rationale ≤ 200, final reply ≤ 3
  lines; a summary of what the meta-agent needs to understand and reproduce the result (record IDs, the best
  structure, each failure with its cause in a line, reusable components, the next step), about 300 words unless the
  diagnosis needs more.
- Stay within the direction and the budget; no unplanned side audits or score-only reruns. If reproduction,
  provenance or scoring contradicts the plan, stop the affected comparison, report a one-line blocker with the
  evidence (detached workers: in `agent_s/BLOCKER.md`; in-session agents: in the reply), and run only the smallest
  diagnostic needed.
- An evaluation is finished and recorded before its session ends, or leaves `attempt_i/.job` saying how to harvest it.

## 4. Budget, limits and estimates
- The evaluation budget is one ledger (`phases/1_setup.md` §6), enforced by the harness, which charges each fit at
  submission.
- Each limit has a kind, recorded in the plan: a *planning estimate* (reported, never enforced); a *submission
  cutoff* (the harness refuses new work, running work finishes); or an *execution limit* (running work is stopped at
  it, by a scheduler time limit or cancellation, checkpointing where possible). A cutoff alone does not bound running
  work, so admit new work only while the work already committed fits under the limit. Without a scheduler limit or
  someone to cancel (a local launcher running unattended), a hard wall-time limit is only a submission cutoff: say
  so. A hard limit the user sets overrides the rule against disrupting work.
- A usage allowance that cannot be read during the run can be bounded only through the amount of work queued, chosen
  conservatively, with the user's readings before and after the pilot as the conversion; the launcher resumes workers
  after each usage-limit reset, so queued work keeps drawing on the allowance. Tell the user which limits can be
  enforced and how.
- Estimate from a representative scored attempt plus setup, review and finalization; state unknowns; update after
  the first meta-iteration. Usage ≈ S × I × usage per attempt + the meta-agent. Wall time ≈ the slowest agent's
  chain: I × (agent work + queue + evaluation + time to notice) + review. Compute ≈ evaluations × cost. Parallelism
  buys progress per hour with usage and compute. Do not convert tokens into a share of an allowance or into money
  without the user's reading or prices.
- **Token budget (heavy): an estimate, not a limit.** Plan one per meta-iteration: S × I × model calls × median
  context, both from the last usage log or, for the first, the pilot (unmeasured guesses are unreliable; say which).
  Give agents the matching soft guide (calls per attempt, when to end a session) in COMMON_PROMPT.md, never stop or
  disrupt agents for exceeding it, report planned against actual after every meta-iteration (`heavy.md` §3) and
  re-plan from the difference (§5).

## 5. Re-plan at every boundary
Re-choose directions, S, I, allocations and (heavy) the token budget from the last meta-iteration. Retire a direction
when the evidence says its premise is wrong or another component limits it, not merely because one round gained
nothing; keep a bounded share for distinct untested hypotheses (exploratory directions, `phases/3_iterate.md`,
attempts), and record why each direction continues, merges or stops. Diagnose wasted fits before changing screening
instructions or agent-model allocation. Review persistent gate failures; propose continued work, a changed
requirement or no eligible result. Report the plan; obtain approval for changes outside delegated scope. Reassess the
number of agents each time and merge the best lineages where they have become compatible or converge: fewer agents
cost less and concentrate effort, while separate directions keep distinct hypotheses alive.
