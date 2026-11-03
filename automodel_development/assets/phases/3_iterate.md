---
name: iterate
description: Third and main phase. Orchestrate the meta/inner agent loop. With the user, choose iteration parameters, orchestration and models (light searches run sub-agents in the session; heavy searches run detached worker sessions launched and reviewed from the session); run S parallel agents per meta-iteration, each making I sequential structural modifications; review results and usage, re-plan at every boundary, and repeat until the user is satisfied with the selection score.
entry: CONTEXT.md exists; end-to-end pipeline verified for baseline model. If `meta_*/` directories already exist, resume from the highest meta-iteration (harvest unfinished agents first) rather than restarting.
exit: User satisfied with the selection score; CONTEXT.md updated with final summary and self-sufficient for Phase 4
---

# Phase 3 — Iterate

---

## Setup (with user)
Read `CONTEXT.md` to restore context. Then:

1. **Diagnose before directing.** From the baseline's residuals (later: the last review), find where the error is and
   what drives it. A direction aimed at a failing region or gate is worth an agent only once you know what limits it.
2. **Working mode.** *Agents iterate* (default): each agent proposes, fits and evaluates its own attempts, for
   expensive evaluations or problems that need diagnosis between attempts. *Batch proposals*: each agent returns an
   annotated batch of candidates in one pass; the meta-agent validates, de-duplicates and fits them centrally, then
   returns the leaderboard and the cost of each unit of complexity to the next round, for candidates that are strings
   or small edits scored by a fixed, cheap evaluator. Hybrids are fine.
3. **Orchestration** (`assets/resources.md` §1–2): light search → in-session sub-agents; heavy → hybrid workers.
4. **Directions and estimate.** Draft non-overlapping directions, classify them (heavy: `resources.md` §4), and estimate
   usage, wall time and compute (`resources.md` §5) from the Phase 2 calibration or the usage log.
5. **Plan approval.** Fill part B of `RUN_PLAN.md` (items 12–18) with a recommendation and alternatives where the
   choice matters (`resources.md` §6): **M** (or a stop rule, e.g. two consecutive meta-iterations gaining less than
   an agreed fraction), **S** (agents in parallel), **I** (attempts per agent in sequence), directions, models and
   effort, the estimate, and whether to pause between meta-iterations (default: continue for light searches, pause
   for heavy ones). Show the whole plan, parts A and B, and launch nothing until the user approves it.
6. Record the approved plan's version in `CONTEXT.md`.

---

## Execution — meta loop
For each meta-iteration `m = 1, 2, …`:

### 1. Launch
Each agent works only in `meta_m/agent_s/` and gets:
- its seed: the baseline if `m = 1`, otherwise the seeds chosen at the last review (with several targets, the current
  incumbent for each);
- a distinct direction, with scope limits (what it must not do);
- relevant material from the project's `references/` folder;
- the shared harness and protocol, so results are comparable: fit on `train.X`, evaluate on `train.X` and
  `validation.X` (or what applies, e.g. cross-validation);
- the attempt contract: each attempt leaves `attempt_i/plan.md`, `model.X`, the harness's `card.md` and a short
  `evaluation.md`, and no evaluation pending (each evaluation runs to completion and is written up before the agent
  moves on or returns);
- the waiting and context rules (`assets/resources.md` §3; light: only the output and prose caps);
- heavy: its `class: …; model: …; effort: …` header.

**In-session:** launch the S sub-agents in parallel in one message, with the models and effort of the plan. If a usage
limit stops them, resume each after the reset with an instruction to harvest pending jobs first; the files on disk are
their state.

**Hybrid:** write `meta_m/COMMON_PROMPT.md` (the shared items above), `meta_m/agent_s/DIRECTION.md` and
`meta_m/agents.conf`; run preflights; launch and wait as in `assets/resources.md` §2b. Workers keep `notes.md` and
`exchange.md` per agent and write `summary.md` at the end.

**Batch proposals** (in-session agents): I is the number of rounds. In each round every agent writes `meta_m/agent_s/round_i.md`: a
batch of candidates (the number agreed at setup) in the harness's input format, each with a one-line rationale, and
nothing else. The meta-agent validates and de-duplicates them (after any canonical simplification), fits all of them
centrally through the harness in one parallel script, and gives the next round the leaderboard, the failures and the
score cost of each unit of complexity.

### 2. Attempts (each agent, I times; agents-iterate mode)
1. Plan one *structural* modification (new terms, a different functional form, changed layers), based on the previous
   attempt's results, in particular where it fits worst (residual structure, worst region or subgroup). Screen it
   cheaply first when full evaluations are expensive (`assets/checks.md`, Iterate).
2. Implement it in `meta_m/agent_s/attempt_i/model.X`, commented so the choices are clear.
3. Fit and evaluate through the shared harness; write `evaluation.md` (what changed, what the card shows, what was
   learned).
4. Continue from the better of this attempt and its parent.

### 3. Review (no user involvement)
Once all S agents have finished:
- Treat any agent without complete written results (crash, NaNs, unfinished job) as a dead lineage: do not compare it;
  clean up orphaned processes.
- Shortlist the best attempts across agents and re-evaluate them yourself through the common protocol, refitted to
  convergence (`assets/checks.md`, Iterate): sub-agents' point estimates from differing fit settings are not directly
  comparable, and small gaps may be within run-to-run noise (`TIPS.md`).
- Record which structural changes helped and which did not; recombine compatible parts of different agents' candidates
  yourself (recombinations often produce the winners) and choose the next seeds.
- Usage: one line (light), or the usage log (heavy; `assets/resources.md` §6).
- Re-plan the next meta-iteration (`resources.md` §7): directions, S, I and R from this one's gains and costs; apply the stop rule.
- Heavy searches: before launching the next meta-iteration, have a fresh reviewer (a new session, or another framework)
  check the review and the next plan; fresh readers catch defects the authors miss.

### 4. Context dump (each meta-iteration)
Update `CONTEXT.md`: best selection score and its attempt; structural changes that worked and did not; seeds and
directions for the next meta-iteration with the reasons for S, I and R; usage summary.

Then send the user a short progress message (a few lines: best score and the attempt that produced it, what
changed, the plan for the next meta-iteration, usage and time so far). If the plan says to pause, or the next
meta-iteration needs a change the plan does not allow, wait for the user's review and guidance. Otherwise continue,
unless the stop rule fires or M is reached: then go to the review with the user.

---

## Review with user
Present:
- the best selection score per meta-iteration (plot) and the structural changes that drove it;
- usage, wall time and compute consumed, and the estimated cost of one more meta-iteration under the current plan and
  a cheaper and a stronger alternative.

Ask the user:
- **Continue iterating?** → return to Setup, choosing new M/S/I/R; continue the meta-iteration numbering so earlier
  logs are not overwritten. If the last batch returned bulky output into the conversation, **suggest compacting**
  first.
- **Satisfied with the selection score?** → proceed to Phase 4 — Finalize.

When the search stops (finished, or stopped by the user), stop any servers, queued jobs or background processes it
started, and record that in `CONTEXT.md`.

---

## Context dump (before handing off to Finalize)
Update `CONTEXT.md` with:

- Path to the best model file and its selection score and metrics;
- Final search summary: what was tried, what worked, rationale for stopping.

Finally, **verify `CONTEXT.md` is self-sufficient** — it must point to the best model file and carry the full search summary, so Phase 4 can run from it alone. If the search left bulky output in the conversation, **suggest the user compact it** before proceeding to Phase 4 — Finalize.
