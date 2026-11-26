# Detached workers

Read when the plan uses detached workers (`resources.md` §1–2). The meta-agent stays in the user's session and does
not supervise attempts; each attempt is a fresh non-interactive session started by
`<skill>/scripts/launch_workers.sh` (formats and options in its header).

1. Write `meta_m/COMMON_PROMPT.md` from `assets/COMMON_PROMPT.md`, `meta_m/agent_s/DIRECTION.md`, `meta_m/agents.conf` and the
   harness's validator `meta_m/done_attempt.sh` (formats in the header of `<skill>/scripts/launch_workers.sh`). When
   evaluations run as scheduler jobs, also write `meta_m/job_state.sh` (from the harness: running / finished but not
   collected / none, per attempt) so sessions end at job boundaries (phase sessions, below); optionally
   `meta_m/WORKER_RULES.md`, the few standing rules workers need that are not in COMMON_PROMPT.md.
2. Use the plan's approved worker permissions: write roots, network and compute access, the least the runtime
   supports. Needing the network is not a reason to drop every boundary. Isolation drops the user's and the project's
   instruction files, so when preparing a meta-iteration copy into `WORKER_RULES.md` the rules from them that bind
   workers (resource limits, cluster etiquette, forbidden actions) and show them to the user with the permissions. The launcher needs bash ≥ 4, `setsid`
   and GNU coreutils (Linux; `tests/run_tests.sh` checks a machine). If the approved configuration is unavailable, run
   in-session or sequentially instead.
3. From a session whose processes may outlive their command (`frameworks.md`), use a validated project launcher with
   this contract, or launch `setsid nohup <skill>/scripts/launch_workers.sh meta_m >> meta_m/launch.log 2>&1 < /dev/null &`
   (append, so a relaunch keeps the earlier log). The launcher must outlive the user's session for as long as the
   meta-iteration runs: when evaluations run on a cluster, or the user will be away, run it there as a job
   (`frameworks.md`, workers on another machine). Reviews need the meta-agent, so for an absence show the user what
   will run and what will sit idle, and let them choose: size the queued work (one meta-iteration, more attempts per
   agent) to fill it, or accept the idle time. Set `AM_STOP_AT` to the end of the absence or to the time the stated
   usage would run out, whichever is earlier: the launcher then creates `STOP`, so nothing new starts. Each attempt
   is a fresh non-interactive session; memory between attempts is the agent's `notes.md` (≤ 300 words) and
   `exchange.md` lists components others may import. With `job_state.sh`, an attempt is split into phase sessions:
   the worker submits work, writes `attempt_i/STATE.md` (≤ 150 words: pending work, how to collect it, next steps) and
   ends its session; the launcher polls the hook without model calls and starts a short resume session when the jobs
   finish. This removes in-session polling and resets the context at each job boundary, which in long attempts is the
   largest share of input. Phase resumptions, and sessions stopped by a usage or rate limit, spend no retry (the
   launcher waits through limit windows). Workers run isolated by default: no instruction files (the project's own
   included), personal instructions, memory, user plugins, skills or MCP servers (details per CLI and the remaining
   gaps in `frameworks.md`); context that workers need goes into COMMON_PROMPT.md or WORKER_RULES.md. The launcher
   can also run on the cluster itself (`frameworks.md`). The launcher takes exclusive ownership (`meta_m/.lock`) before
   starting workers, retries incomplete sessions a bounded number of times, and starts no new session or hook once
   `meta_m/STOP` exists. On interruption it stops its recorded worker process groups and keeps the lock if it cannot
   confirm they are gone; after a crash, `launch_workers.sh --reclaim meta_m` releases it only when the registered
   launcher and the recorded worker groups are no longer alive. Before relaunching, check each `.job` receipt's state with the scheduler; a finished job is
   collected by that agent's resume session (its `STATE.md` says how), so harvest it yourself only if there is no
   `STATE.md`, and never resubmit a job whose receipt is uncertain. A relaunch reuses the meta-iteration's inputs
   unchanged: editing the brief or rules mid-iteration changes the protocol for some attempts only. Stopping local
   processes does not cancel queued jobs. A scheduler's "completed" is not
   success: the validator decides.
4. Watch with `<skill>/scripts/worker_status.sh meta_m` at the agreed cadence (`frameworks.md`); `--wait <s>` returns
   on launcher exit, failure or timeout (start it after the launcher has registered, or it returns at once). The
   status also shows each agent's latest `BLOCKER.md` line: deal with a blocker when it appears, since the agent
   reporting it is working around it. Review when all agents finish.
