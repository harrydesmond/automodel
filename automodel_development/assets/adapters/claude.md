# Claude Code (checked on 2.1.x)

Re-check flags and limits with `--help` or the tool definitions when planning, and record what you confirmed in
`CONTEXT.md`. No model names here, since line-ups change: offer concrete names from the exposed tool choices or a
verified list (`--model` accepts names but does not enumerate availability).

- **In-session sub-agents:** the Agent tool, with per-agent `model` and `effort` (set effort only when the approved
  plan asks for it). Launch a meta-iteration's agents in one message, in the background; resume a stopped one with
  SendMessage. The orchestrator is the session's model, chosen by the user (`/model`).
- **Detached workers:** `claude -p "<prompt>" --model <model> --effort <low|medium|high|xhigh|max>` plus the approved
  permission flags in `AM_CLAUDE_FLAGS`: `--permission-mode default`, in which a headless session is refused anything
  not allowed, with `--allowedTools` rules for reading, the write roots (`Edit(<dir>/**)` covers writes too; the
  launcher turns `{agent_dir}` into each worker's folder) and the harness commands. `acceptEdits` lets a worker write
  anywhere in its working directories, and a shell rule that runs code the worker wrote bypasses every file rule, so
  then the write roots hold only as far as the operating system enforces them; say so when proposing permissions.
  `bypassPermissions` only if the user explicitly approves it. A `-p` session ends with its turn: a worker waits in
  the foreground and leaves no background job behind.
- **Residual context:** by default a session also loads the user's personal instruction file, every instruction file
  in the directories above it, auto-memory, user plugins, skills and MCP listings, which can double a worker's fixed
  context and bring in unrelated rules; `CLAUDE.md` files in subfolders load when a worker reads files there. The
  launcher turns these off, the project's own instruction files at any depth included (`launch_workers.sh` header);
  `--bare` would do more but accepts only API-key authentication, not subscription logins.
- **Waiting:** prefer phase sessions (`detached.md`), which end the session at a job boundary. Otherwise a foreground
  command blocks for at most 10 min, so a worker's long wait is a harness command that blocks ≈ 9.5 min (with the tool
  timeout at the maximum) and reports the job's state, repeated. In the interactive session, a background command
  that returns when work is done (e.g. `worker_status.sh meta_m --wait <s>`, when the launcher runs on this machine)
  wakes the meta-agent with its completion notice. Cache expiry can make longer gaps costlier; compare total cost.
- **Usage:** completion notices give per-agent tokens and duration; `usage_report.py claude` reads the session logs
  (`~/.claude/projects/`, or `$CLAUDE_CONFIG_DIR`). Local transcripts expire after some weeks: keep prompts and
  returns in the project. The allowance reading (`/usage`) comes from the user.
- **Known behaviour:** writes of report-like files by sub-agents are sometimes refused; have them return the text
  (within the summary limit: it enters your context) and save it yourself. A usage-limit stop ends all running
  in-session sub-agents at once: resume each with SendMessage after the reset, harvesting pending jobs first. Detached
  workers stop with a "hit your … limit" (rate_limit, HTTP 429) error, which the launcher waits through.
- **Orchestrator context:** the orchestrator cannot compact itself; at checkpoints ask the user to `/compact`, or to
  start a new session that resumes from `CONTEXT.md` (usually leaner). An in-session sub-agent re-reads its fixed
  context (system prompt, tools, loaded instruction files) on every call; check its size from the first call in the
  usage log.
- **Login on another machine** (`cluster.md`): run `claude setup-token` once, in a terminal rather than through an
  agent; keep the token in an owner-only file and pass it as `CLAUDE_CODE_OAUTH_TOKEN` in the job script. Several
  accounts, where their terms allow one workload across them: one token file each, listed in order of preference in
  `AM_CLAUDE_TOKENS`; workers move to the next on a usage limit and return to the first once it has usage again
  (`launch_workers.sh` header).
