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
   harness's validator `meta_m/done_attempt.sh` (formats in the header of `<skill>/scripts/launch_workers.sh`).
2. Agree the workers' permissions with the user: write roots, network and compute access, the least the runtime
   supports. Needing the network is not a reason to drop every boundary. The launcher needs bash ≥ 4, `pgrep` and
   `setsid` (Linux; on macOS install a newer bash). If the approved configuration is unavailable, run in-session or
   sequentially instead.
3. Launch `setsid nohup <skill>/scripts/launch_workers.sh meta_m > meta_m/launch.log 2>&1 < /dev/null &`. Each attempt
   is a fresh non-interactive session; memory between attempts is the agent's `notes.md` (≤ 300 words) and
   `exchange.md` lists components others may import. The launcher takes exclusive ownership (`meta_m/.lock`) before
   starting workers, retries incomplete sessions a bounded number of times, and starts no new session or hook once
   `meta_m/STOP` exists. On interruption it stops its recorded worker process groups and keeps the lock if it cannot
   confirm they are gone; after a crash, `launch_workers.sh --reclaim meta_m` releases it only when the registered
   launcher and the recorded worker groups are no longer alive. Reconcile submitted jobs before relaunching (harvest a known job; never resubmit one whose receipt is
   uncertain without checking); stopping local processes does not cancel queued jobs. A scheduler's "completed" is not
   success: the validator decides.
4. Watch without spending model calls: once the launcher has registered, `<skill>/scripts/worker_status.sh meta_m
   --wait <s>` returns when it exits, a failure is logged or <s> pass (at once if no launcher runs) (in Claude Code run it in the background; its completion notice wakes the session;
   in Codex, wait with the sleep tool for a time chosen from the observed attempt durations, then run it once).
   Report progress at the agreed cadence; review when all agents finish.

## 3. Waiting and context rules (for prompts and COMMON_PROMPT.md)
Input volume ≈ model calls × context per call, and it usually dominates; output is far smaller (though priced higher).
- Never poll at short intervals. Wait for a long command with one blocking wait matched to its expected remaining
  duration and the delay you can tolerate in noticing it, then one short status check; prefer completion
  notifications. This applies to screens and checks too.
- Long outputs go to files; print tails (≤ ~40 lines). The harness's record and card replace hand-written tables.
  Keep prose short: plan ≤ 150 words, rationale ≤ 200, `summary.md` ≤ 800, final reply a few lines.
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
- Estimate from a representative scored attempt (proposal, screening, queue, fitting, harvesting) plus setup and
  review; name what is unmeasured, and update after the first meta-iteration.
- Usage ≈ S × I × usage per attempt + the meta-agent. Wall time ≈ the slowest agent's chain: I × (agent work + queue +
  evaluation + time to notice) + review. Compute ≈ evaluations × cost. Parallelism (agents, or variants per attempt
  evaluated together) buys progress per hour with usage and compute; sequence costs wall time.
- Do not convert tokens into a share of an allowance or into money without the user's reading or prices.
- Measure total worker, supervisor, summary and review usage on this workload. Fresh attempt sessions can reduce
  repeated context, but setup and hand-over costs can offset the saving; compare validated results within the same
  total budget.

## 6. Usage log (heavy)
`launch_workers.sh` writes `meta_m/launch_manifest.jsonl` (agent, session label, model, effort, start/end). At each
review run `python3 <skill>/scripts/usage_report.py <claude|codex> --cwd <project> --since <launch> --until <now>` into
`meta_m/usage_log.jsonl` (times in UTC, e.g. the first `time` in `launch_manifest.jsonl`): it counts usage events inside the window (a meta-agent session that began earlier is
included for its in-window calls only), separates uncached input, cache reads/writes and output, and tags workers by
their launch prompt. "Input after waits" is a heuristic. Add per agent: proposals, screens, scored fits, attempts validated and quarantined, gain over its seed, wall time. Summary line in `CONTEXT.md`; mark allowance readings unknown unless the user
supplies them.

## 7. Re-plan at every boundary
Re-choose directions, S, I and allocations from the last meta-iteration. Retire a direction when the evidence says its
premise is wrong or another component limits it, not merely because one round gained nothing; keep a bounded share
for distinct untested hypotheses, and record why each direction continues, merges or stops. Treat many wasted fits as
a call for better screening instructions, not a bigger model. Report the new plan in the progress message; ask the
user only for changes outside the delegated scope or a material budget increase.
