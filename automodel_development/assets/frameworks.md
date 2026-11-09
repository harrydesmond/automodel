# Framework mechanics

No model names here: line-ups change. CLI flags and limits were checked on the versions named; re-check with `--help`
or the tool definitions when planning, and record what you confirmed in `CONTEXT.md`. Offer models as concrete names
from exposed tool choices or a verified model list; CLI `--model` accepts names but does not enumerate availability.

## Claude Code (checked on 2.1.x)
- **In-session sub-agents:** the Agent tool, with per-agent `model` and `effort` (set effort only when the approved
  plan asks for it). Launch a meta-iteration's agents in one message, in the background; resume a stopped one with
  SendMessage. The orchestrator is the session's model, chosen by the user (`/model`).
- **Detached workers:** `claude -p "<prompt>" --model <model> --effort <low|medium|high|xhigh|max>` plus the approved
  permission flags in `AM_CLAUDE_FLAGS` (e.g. `--permission-mode acceptEdits` with `--allowedTools` for the commands
  the harness needs; `bypassPermissions` only if the user explicitly approves it). A `-p` session ends with its turn:
  a worker waits in the foreground and leaves no background job behind.
- **Waiting:** a foreground command blocks for at most 10 min, so a worker's long wait is a harness command that
  blocks ≤ ~9.5 min and reports the job's state, repeated. In the interactive session, a background command that
  returns when work is done (e.g. `worker_status.sh meta_m --wait <s>`) wakes the meta-agent with its completion
  notice. Cache expiry can make longer gaps costlier; compare total cost.
- **Usage:** completion notices give per-agent tokens and duration; `usage_report.py claude` reads the session logs
  (`~/.claude/projects/`). Local transcripts expire after some weeks: keep prompts and returns in the project. The
  allowance reading (`/usage`) comes from the user.
- **Known behaviour:** writes of report-like files by sub-agents are sometimes refused; have them return the text and
  save it yourself. A usage-limit stop ends all running in-session sub-agents at once.

## Codex (CLI checked on 0.167.0; tools vary by session)
- **In-session:** use exposed agent tools and limits. Full-history forks may require inherited model/effort; supply
  a fresh brief when overriding them. Check effective capacity before launching S agents.
- **Detached:** `codex exec -m <model> -c 'model_reasoning_effort="<effort>"' -C <project> -o <reply>
  "<prompt>" < /dev/null`. Use `--skip-git-repo-check` outside repositories. Set approved sandbox, write-root and
  network permissions explicitly; project-root access does not isolate agent folders. With the sandbox on
  (`-s workspace-write`, the launcher's default) the network is off and background processes die with the command
  that started them (checked on 0.167): that suits evaluations run in the foreground; cluster submission, local
  background jobs and a meta-agent starting the launcher need the wider permissions the user approves.
- **Waiting:** inspect active tools and instructions. Observed maxima: `sleep` 12 h, `wait_agent` 1 h,
  `exec_command` yield 30 s, empty `write_stdin` poll 5 min. Observed sessions discouraged blocking waits over 60 s;
  workers mostly kept short sleeps despite longer-wait prompts, with almost all repeated input cached. Set cadences
  within applicable limits; assess cost using `resources.md` §3.
- **Usage:** `usage_report.py codex` reads local session logs; check coverage against launched sessions. Allowance
  readings come from the user.

## Other frameworks
Fill in the same fields with the user. Without parallel sub-agents, use detached workers if there is a
non-interactive mode, otherwise run agents sequentially, and record it.
