# Detached workers

Read when the plan uses detached workers (`resources.md` §1–2). The meta-agent stays in the user's session and does
not supervise attempts; each attempt is a fresh non-interactive session started by
`<skill>/scripts/launch_workers.sh` (Claude Code or Codex; formats, options and recovery details in its header).

1. **Inputs.** Write `meta_m/COMMON_PROMPT.md` from `assets/COMMON_PROMPT.md`, `meta_m/agent_s/DIRECTION.md`,
   `meta_m/agents.conf` and the harness's validator `meta_m/done_attempt.sh`. When evaluations run as scheduler jobs,
   also write `meta_m/job_state.sh` (from the harness: running / finished but not collected / none, per attempt), so
   sessions end at job boundaries. A relaunch reuses these inputs unchanged: editing them mid-iteration changes the
   protocol for some attempts only.
2. **Permissions and rules.** Use the plan's approved worker permissions (write roots, network, compute), the least
   the runtime supports; needing the network is not a reason to drop every boundary. Workers run with reduced
   context: the launcher drops instruction files (the project's own included), memory, plugins, skills and MCP
   servers as far as each CLI allows; what still loads is in its adapter. So when preparing a meta-iteration, copy
   into `meta_m/WORKER_RULES.md` every rule from the user's and the project's instruction files that binds workers
   (resource limits, data access, scientific conventions, forbidden actions), end it with a list of the rules left
   out and why, and show both to the user with the permissions; the pilot checks that the carried rules reached the
   worker. The launcher needs bash ≥ 4, `setsid` and GNU coreutils (`tests/run_tests.sh` checks a machine). If the
   approved configuration is unavailable, run in-session or sequentially instead.
3. **Launch.** From a session whose processes may outlive their command (adapter), use a validated project launcher
   with this contract, or `setsid nohup <skill>/scripts/launch_workers.sh meta_m >> meta_m/launch.log 2>&1 <
   /dev/null &` (append, so a relaunch keeps the earlier log). The launcher must outlive the user's session for as
   long as the meta-iteration runs: when evaluations run on a cluster, or the user will be away, run it there as a
   job (`adapters/cluster.md`). Reviews need the meta-agent, so for an absence show the user what will run and what
   will sit idle, and let them choose: size the queued work (one meta-iteration, more attempts per agent) to fill it,
   or accept the idle time.
4. **How workers run.** Memory between attempts is the agent's `notes.md` (≤ 300 words); `exchange.md` lists
   components others may import. With `job_state.sh`, a worker submits work, writes `attempt_i/STATE.md` (≤ 150
   words: pending work, how to collect it, next steps) and ends; the launcher polls the hook without model calls and
   starts a resume session when the jobs finish. Phase resumptions and limit stops spend no retry. Nothing new starts
   once `meta_m/STOP` exists.
5. **Recovery.** After a crash, `launch_workers.sh --reclaim meta_m` releases the lock only when the registered
   launcher and its worker groups are gone. Before relaunching, check each `.job` receipt with the scheduler: a
   finished job is collected by that agent's resume session (its `STATE.md` says how), so harvest it yourself only if
   there is no `STATE.md`, and never resubmit a job whose receipt is uncertain. Stopping local processes does not
   cancel queued jobs; a cancellation (`SKILL.md`) cancels them from their receipts. After a stop the launcher starts
   no session, resumptions included: collect finished jobs through the harness from their receipts, or record them as
   pending. A scheduler's "completed" is not success: the validator decides.
6. **Watching.** Run `<skill>/scripts/worker_status.sh meta_m` at the agreed cadence (adapter; on a cluster,
   `adapters/cluster.md`); `--wait <s>` returns on launcher exit, failure or timeout (start it after the launcher has
   registered, or it returns at once; it works only on the launcher's machine). The status shows each agent's latest
   `BLOCKER.md` line: deal with a blocker when it appears, since the agent reporting it is working around it. Review
   when all agents finish.
