# Resources: size, orchestration, waiting, models, budget and usage

`<skill>` is this skill's folder; its scripts are run from the project root.

## 1. Search size
| | light | heavy |
|---|---|---|
| when | evaluations of seconds; the search is a small share of the user's allowance | evaluations of minutes to hours or queued, or usage that could approach the allowance |
| plan | compact plan, approved once | part A (setup), then part B after calibration |
| orchestration | in-session sub-agents | detached workers (§2) when evaluations are long; otherwise in-session |
| models | the session's model, or one model for all agents | options per direction (§4) |
| usage record | one line per meta-iteration | usage log (§6) |
| between meta-iterations | progress message, continue | progress message, pause for review |

Keep budget, evaluation latency and stakes apart: a million cheap evaluations can be costly without needing detached
workers, and one slow evaluation may need a watcher but no model planning. If unsure, start light and switch at a
boundary when measurements say so.

## 2. Orchestration
**In-session sub-agents.** The meta-agent launches the agents with the framework's sub-agent tool and reviews when
their completion notices arrive. Each wake-up of an agent re-reads its own growing context, so give each agent one
session per meta-iteration and fresh agents for the next one, briefed by the review.

**Detached workers (hybrid; default for long evaluations).** The meta-agent stays in the user's session and does not
supervise attempts:
1. Write `meta_m/COMMON_PROMPT.md` (harness, decision rule, budget, how to wait, what an attempt leaves on disk,
   the `summary.md` specification, scope limits), `meta_m/agent_s/DIRECTION.md`, `meta_m/agents.conf` and the
   harness's validator `meta_m/done_attempt.sh` (formats in the header of `<skill>/scripts/launch_workers.sh`). When
   evaluations run as scheduler jobs, also write `meta_m/job_state.sh` (from the harness: running / finished but not
   collected / none, per attempt) so sessions end at job boundaries (phase sessions, below); optionally
   `meta_m/WORKER_RULES.md`, the few standing rules workers need that are not in COMMON_PROMPT.md.
2. Use the plan's approved worker permissions: write roots, network and compute access, the least the runtime
   supports. Needing the network is not a reason to drop every boundary. The launcher needs bash ≥ 4, `pgrep` and
   `setsid` (Linux; on macOS install a newer bash). If the approved configuration is unavailable, run in-session or
   sequentially instead.
3. From a session whose processes may outlive their command (`frameworks.md`), use a validated project launcher with
   this contract, or launch `setsid nohup <skill>/scripts/launch_workers.sh meta_m > meta_m/launch.log 2>&1 < /dev/null &`. Each attempt
   is a fresh non-interactive session; memory between attempts is the agent's `notes.md` (≤ 300 words) and
   `exchange.md` lists components others may import. With `job_state.sh`, an attempt is split into phase sessions:
   the worker submits work, writes `attempt_i/STATE.md` (≤ 150 words: pending work, how to collect it, next steps) and
   ends its session; the launcher polls the hook without model calls and starts a short resume session when the jobs
   finish. This removes in-session polling and resets the context at each job boundary, which in long attempts is the
   largest share of input. Phase resumptions, and sessions stopped by a usage or rate limit, spend no retry (the
   launcher waits through limit windows). Claude workers run isolated by default: no instruction files above the
   project root, no personal instruction file or auto-memory, no user plugins, skills or MCP servers; context that
   workers need goes into COMMON_PROMPT.md or WORKER_RULES.md. The launcher takes exclusive ownership (`meta_m/.lock`) before
   starting workers, retries incomplete sessions a bounded number of times, and starts no new session or hook once
   `meta_m/STOP` exists. On interruption it stops its recorded worker process groups and keeps the lock if it cannot
   confirm they are gone; after a crash, `launch_workers.sh --reclaim meta_m` releases it only when the registered
   launcher and the recorded worker groups are no longer alive. Reconcile submitted jobs before relaunching (harvest a known job; never resubmit one whose receipt is
   uncertain without checking); stopping local processes does not cancel queued jobs. A scheduler's "completed" is not
   success: the validator decides.
4. Watch with `<skill>/scripts/worker_status.sh meta_m` at the agreed cadence (`frameworks.md`); `--wait <s>` returns
   on launcher exit, failure or timeout. Review when all agents finish.

## 3. Waiting and context rules (for prompts and COMMON_PROMPT.md)
Input ≈ model calls × context per call, and every call re-reads the whole context, so long sessions dominate: the
number of calls and the size the context grows to matter more than any single output. Price uncached input, cache
writes/reads and output separately; gross tokens alone do not measure cost.
- Do not poll from a model session. Prefer phase sessions (§2); otherwise completion notifications; otherwise a
  harness wait command used close to the longest single blocking call the framework allows (`frameworks.md`), then
  check once. A shell watcher may poll internally without waking the model.
- Keep the context small: do analysis in short script files that print compact summaries (several questions per run)
  rather than many exploratory one-line commands; never print large files or full arrays; create and modify large
  candidate files with generator scripts or targeted edits, not by rewriting them in the conversation; read others'
  files through their summaries and exchange notes. Give each attempt a soft guide for model calls (from the token
  budget, §5) and end a phase rather than letting a session grow.
- Long outputs go to files; print tails (≤ ~40 lines). The harness's record and card replace hand-written tables; the
  card should carry the diagnostics agents need most (e.g. error breakdowns by the main data dimensions), so agents
  do not each re-derive them. Keep prose short: plan ≤ 150 words, rationale ≤ 200, `summary.md` ≤ 800, final reply a
  few lines.
- Stay within the direction and the budget; no unplanned side audits or score-only reruns. If reproduction, provenance or
  scoring contradicts the plan, stop the affected comparison, send one short blocker with the evidence, and run only
  the smallest diagnostic needed.
- An evaluation is finished and recorded before its session ends, or leaves `attempt_i/.job` saying how to harvest it.

## 4. Models and effort
Start with the session's model and the simplest execution path. Offer other allocations as options to test, with
their estimated cost and uncertainty, when measured cost or quality warrants it: e.g. a cheaper model for mechanical
directions (convergence refits, speed-ups at fixed accuracy, fixed-protocol measurements), the strongest model for
directions that must diagnose failures and overturn their own brief, or fewer agents at a higher level. Name concrete
models (`frameworks.md`), not tiers. None of these allocations has been compared under controlled conditions.

## 5. Budget and estimates
- The approved evaluation budget (screens and scored fits per attempt; run-wide fit, wall-time and compute caps,
  counting baselines, failures, refits and recombinations) is enforced by the harness, not only estimated.
- Estimate from a representative scored attempt plus setup, review and agreed finalization; state unknowns and
  update after the first meta-iteration.
- Usage ≈ S × I × usage per attempt + the meta-agent. Wall time ≈ the slowest agent's chain: I × (agent work + queue +
  evaluation + time to notice) + review. Compute ≈ evaluations × cost. Parallelism (agents, or variants per attempt
  evaluated together) buys progress per hour with usage and compute; sequence costs wall time.
- Do not convert tokens into a share of an allowance or into money without the user's reading or prices.
- **Token budget: a guide, not a limit.** Plan one per meta-iteration (S × I × tokens per attempt, with tokens per
  attempt ≈ model calls × median context; take both from the previous meta-iteration's usage log, or a rough guess
  for the first, and say which). Give agents the corresponding soft guide (calls per attempt, how often to end a
  phase) in COMMON_PROMPT.md. Do not spend significant effort pinning the estimate down, and never stop, cancel or
  disrupt agents for exceeding it: token use is hard to predict. Report planned against actual after every
  meta-iteration (§6) and use the difference to re-plan S, I, models, effort and the context rules (§7).
- Measure total worker, supervisor, summary and review usage on this workload. Fresh attempt and phase sessions
  reduce repeated context; their start-up and hand-over cost is small by comparison but not zero.

## 6. Usage log (heavy)
`launch_workers.sh` writes `meta_m/launch_manifest.jsonl` (agent, session label, model, effort, start/end). At each
review run `python3 <skill>/scripts/usage_report.py <claude|codex> --cwd <project> --since <launch> --until <now>` into
`meta_m/usage_log.jsonl` (times in UTC, e.g. the first `time` in `launch_manifest.jsonl`): it counts usage events inside the window (a meta-agent session that began earlier is
included for its in-window calls only), separates uncached input, cache reads/writes and output, and tags workers by
their launch prompt. "Input after waits" is a heuristic. Add per agent: proposals, screens, scored fits, attempts validated and quarantined, gain over its seed, wall time. Summary line in `CONTEXT.md`; mark allowance readings unknown unless the user
supplies them. In the progress message after each meta-iteration, report the token budget against actual use (total
and per agent; calls and median context as the drivers) and what the next meta-iteration will change because of it.

## 7. Re-plan at every boundary
Re-choose directions, S, I, allocations and the token budget from the last meta-iteration. Retire a direction when the evidence says its
premise is wrong or another component limits it, not merely because one round gained nothing; keep a bounded share
for distinct untested hypotheses, and record why each direction continues, merges or stops. Diagnose wasted fits before
changing screening instructions or agent-model allocation. Review persistent gate failures; propose continued work, a changed
requirement or no eligible result. Report the plan; obtain approval for changes outside delegated scope.
