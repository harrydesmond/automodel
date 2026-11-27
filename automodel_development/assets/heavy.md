# Heavy searches

Read once a search is classified heavy (`resources.md` §1), alongside the phase recipes. Detached workers have their
own file (`detached.md`).

## 1. Harness additions (Phase 2)
- **A failure command** that records what the harness cannot detect itself (e.g. a lost job) with its reason: agents
  never write records or results by hand, so every number traces to a fit.
- **A metrics card** (`card.md`, first line a one-line summary) generated from the record, carrying the diagnostics
  agents need most (error breakdowns by the main data dimensions and the regions the requirements single out).
- **A starting toolkit**, seeded from the tools the pilot's agent wrote (Phase 2 §3): the analyses agents would
  otherwise each write, such as evaluation at fixed constants, residual breakdowns, per-gate diagnostics (which
  component fails and by how much), oracle floors and, where the model family allows it, the gain of adding a
  component with the rest held fixed.
- **A completion validator** `done_attempt.sh <attempt_dir>`: exit 0 only when every required variant or control
  has a validated result or recorded failure and no job remains pending. The launcher and the review trust it, not
  prose; the review quarantines failures.
- **Long jobs:** submission that leaves `attempt_i/.job` (how to harvest) while one runs; a wait command that blocks
  up to a given time and then reports the job's state; a non-blocking job-state command (running / finished but not
  collected / none) for the launcher's `job_state.sh` hook. Under phase sessions, submit returns once the receipt is
  written and the worker ends its session.
- **Remote evaluation:** check before every submission that the remote code matches the local code; jobs write
  outputs atomically (temporary file, then rename); harvesting records a missing, unreadable, empty or truncated
  output as a failed work unit with its reason and carries on, since stopping on one would block the attempt.

## 2. Models and effort
Start with the session's model and the simplest execution path. When measured cost or quality warrants it, offer
other allocations as options to test, with their estimated cost and uncertainty: a cheaper model for mechanical
directions, the strongest for directions that must diagnose failures and overturn their brief, or fewer agents at a
higher level. Name concrete models (adapter), not tiers; none of these allocations has been compared under controlled
conditions. Effort mainly changes output (reasoning) tokens: offer lower effort for mechanical directions and check
its effect in the usage log.

## 3. Usage log
At each review run `python3 <skill>/scripts/usage_report.py <claude|codex> --cwd <project> --since <launch> --until
<now>` (`--home <dir>` for a separate agent home; times in UTC, e.g. the first `time` in
`meta_m/launch_manifest.jsonl`) into `meta_m/usage_log.jsonl`; its header explains what it counts. Add per agent:
proposals, screens, scored fits, attempts validated and quarantined, gain over its seed, wall time. Put a summary line
in `CONTEXT.md` (allowance readings unknown unless the user supplies them), and in each progress message the token
budget against actual use (total and per agent; calls and median context as the drivers) and what the next
meta-iteration will change because of it.
