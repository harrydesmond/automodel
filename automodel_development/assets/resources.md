# Resources: search size, orchestration, models and usage

How to organise the agents, wait for evaluations, choose models and effort, estimate what a meta-iteration costs, and
re-plan from what it actually cost. `<skill>` below is this skill's folder; scripts are run from the project root.

## 1. Search size
| | light | heavy |
|---|---|---|
| when | evaluations ≤ ~1 min; the search is small next to the user's allowance | evaluations of minutes to hours (queued jobs), or usage that could approach the allowance |
| orchestration | in-session sub-agents (§2a) | hybrid (§2b) |
| models | the session's model, or one model for all sub-agents | per direction class (§4) |
| estimate | one line: "S×I attempts on <model>; about <share> of your window; ~<wall time>" | §5 |
| usage record | one line per meta-iteration in `CONTEXT.md` | usage log (§6) |
| between meta-iterations | progress message, then continue | progress message, then pause for the user's review |

If unsure, start light and switch at a boundary when the first meta-iteration's usage or wall time says so.

## 2. Orchestration
**(a) In-session sub-agents.** The meta-agent launches the S sub-agents in parallel with the framework's sub-agent tool,
waits for their completion notices, and reviews. Simple and supervised, but every wake-up of an agent re-reads its own
growing context, so it suits cheap evaluations. Keep one session per agent for the I attempts of a meta-iteration (with second-long evaluations, fresh sessions per
attempt would spend more re-reading the brief than they save), but start fresh agents for each meta-iteration, with
the review's seeds and findings as their brief: agents carried across meta-iterations accumulate large contexts.

**(b) Hybrid: the default for heavy searches.** The meta-agent stays in the user's session but does not supervise
attempts:
1. Write the meta-iteration's files: `meta_m/COMMON_PROMPT.md` (shared protocol: how to fit, evaluate and wait; what
   an attempt must leave on disk; the `summary.md` specification; scope limits), `meta_m/agent_s/DIRECTION.md`
   (seed, direction, class) and `meta_m/agents.conf` (agent, CLI, model, effort, attempts; format in the header of
   `<skill>/scripts/launch_workers.sh`).
2. Run preflights (each seed reproduces its score through the shared harness), get the user's approval for unattended
   workers (they run with permission prompts off), then launch `setsid nohup <skill>/scripts/launch_workers.sh meta_m
   > meta_m/launch.log 2>&1 < /dev/null &`. For each agent the launcher runs one fresh non-interactive session per
   attempt, then a summary session. All state is on disk, so re-running it after any stop (usage limit, crash, reboot)
   continues where it stopped.
3. Check once after ~20 min (every agent has a plan and a running or finished first evaluation), then wait in long
   steps (60–90 min, or about one attempt's duration), each followed only by `<skill>/scripts/worker_status.sh
   meta_m`. Do not
   read agent files or run side analyses while waiting.
4. When all agents have finished, review in the same thread (Phase 3 step 3).

In this mode each attempt starts with a fresh, small context. Memory between attempts is the agent's `notes.md`
(≤ 300 words: current best, what worked, queue of next hypotheses). Its `exchange.md` lists components the other agents
may import, which is enough for recombination within a meta-iteration. An optional `meta_m/after_agent.sh` (e.g. a
refit of the agent's best attempt for the review) runs while slower agents finish.

(If the user prefers not to keep a session open, they can start a fresh session for the review instead.)

## 3. Waiting and context rules
Usage ≈ model calls × context length; output (the thinking and writing) is a small share. Put the relevant rules in
the sub-agent prompts or `COMMON_PROMPT.md`; for a light search only the output and prose rules matter:
- Never poll at short intervals. Wait for a long command (any long command: screens and checks included, not only
  scored fits) with one blocking wait matched to its expected duration (from the previous evaluation's duration and the
  time already elapsed), then run one short status check. Use the framework's wait primitives (`frameworks.md`).
- Waits much longer than the evaluation add wall time: the gap between a job finishing and the agent noticing is part
  of every attempt.
- Send long outputs to files and print tails (≤ ~40 lines). A metrics card written by the shared harness (`card.md`,
  first line a one-line summary) replaces hand-written tables. Cap the prose: plan ≤ 150 words, `evaluation.md` ≤ 200
  words of the agent's own beyond the card, `summary.md` ≤ 800 words, final reply a few lines pointing to files.
- Sub-agents message the meta-agent only when blocked, briefly. No audits, score-only reruns or side analyses unless the
  direction asks for them; state scope limits explicitly, because some models inflate the process otherwise.
- An attempt's evaluation finishes and is written up before its session ends. A job that outlives a session (usage
  stop, crash) leaves `attempt_i/.job` saying how to harvest it; the next session harvests it and never resubmits.
- The meta-agent's cost is its wake-ups, not its output: high (not maximum) effort is enough.

## 4. Models per direction (heavy searches)
| class | the agent must… | default |
|---|---|---|
| diagnostic | find why something fails, invent new structure, overturn its own brief when the evidence says so | strong tier, high effort (top tier if it is the bottleneck and the budget allows) |
| integration | recombine parts from several agents, recover accuracy, satisfy constraints or interpretability tests | strong tier, high effort |
| mechanical | speed-ups at fixed accuracy, pruning, convergence refits, fixed-protocol measurements | economy tier, or strong tier at lower effort |

The meta-agent runs on the top tier; its reviews, seeds and recombinations steer every attempt. When the budget binds,
reduce S (merge or drop directions) or I before downgrading every agent: compute does not depend on the model, and an
agent that screens well wastes fewer expensive fits. These defaults are judgement; let the usage log (§6–7) replace
them.

## 5. Estimate the cost
- **Per attempt:** first from the Phase 2 test sub-agent (a scored attempt costs several times the pipeline test), later
  from the usage log. With neither, say the estimate is a guess.
- **Usage** ≈ S × I × usage per attempt, plus the meta-agent: a sizeable share if it waits on in-session agents
  through long evaluations, little in hybrid mode. Batch proposals: one proposal call per agent per round, plus the
  meta-agent's central fitting and review, which usually dominate. Several parallel agents can exhaust a subscription window within a few attempts each; plan for limit
  stops (hybrid workers resume by themselves).
- **Wall time** ≈ the slowest agent's chain: I × (agent work + queue + evaluation + noticing latency), plus the review.
  Cutting usage does not cut wall time unless it removes steps from the chain.
- **Compute** ≈ evaluations (screens included) × time per evaluation × cores.
- **Levers.** Parallelism (more agents, or several variants per attempt evaluated together) buys progress per hour with
  usage and compute; more sequential attempts cost wall time. Long waits save usage and add latency. Fresh sessions per
  attempt cut context when evaluations take minutes or more.
- For orientation, from one heavy run (evaluations ~10 min on a cluster): moving from in-session agents with a
  waiting meta-agent and 1-min polling to hybrid workers with long waits cut usage per attempt 4.6× (2.3× fewer calls ×
  2.1× smaller contexts) and wall time 2×, with no loss of gain per meta-iteration.

## 6. Offer the choice and log usage
- **Choice (in `RUN_PLAN.md` part B; again at a boundary if anything moved).** Heavy: ask the user's limits or
  priorities on usage, wall time and compute (they change during a run), then present M (or a stop rule), S, I and R
  together, where R = orchestration, model and effort per class, and wait settings: a recommendation with its
  evidence and two or three alternatives (e.g. fewer agents at a higher tier; economy tier for mechanical
  directions), each with §5's estimates. Light: one estimate line.
- **Log (heavy).** At each review, run `<skill>/scripts/usage_report.py <claude|codex> --cwd . --since <launch time,
  UTC>` (it reads the session logs, one JSON line per session) into `meta_m/usage_log.jsonl`, and add per agent: class, model, effort, attempts scored and wasted (failed, abandoned),
  wall time split into agent work / queue / evaluation / latency, limit stops, best gain vs seed, and whether the agent
  overturned its brief. Put a summary line in `CONTEXT.md`: totals, usage per scored attempt, allowance used vs planned
  (ask the user for the framework's usage reading), wall time, compute.

## 7. Re-plan at every boundary
Re-choose S, I and R from the last meta-iteration rather than repeating them. Drop or merge directions that gained
nothing or turned out to be limited by something else; diagnose a failing region or gate before assigning a direction
to it. Upgrade directions whose agent stalled, downgrade those a cheaper allocation handled, and treat high usage with
many wasted fits as a call for better screening instructions, not a bigger model. Apply the stop rule. Report the new
plan and its reason in the meta-iteration summary, and re-ask the user only if the estimate moved materially, the
allocation changes, or the budget binds; with pauses on, the
user reviews it anyway.
