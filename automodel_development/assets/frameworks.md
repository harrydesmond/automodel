# Framework mechanics

No model names here: line-ups change. CLI flags and limits were checked on the versions named; re-check with `--help`
or the tool definitions when planning, and record what you confirmed in `CONTEXT.md`. Offer models as concrete names
from the framework's current list (sub-agent tool options, CLI `--model` choices, your own model).

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
  notice. Prompt-cache entries expire during long gaps; prefer fewer, longer waits.
- **Usage:** completion notices give per-agent tokens and duration; `usage_report.py claude` reads the session logs
  (`~/.claude/projects/`). Local transcripts expire after some weeks: keep prompts and returns in the project. The
  allowance reading (`/usage`) comes from the user.
- **Known behaviour:** writes of report-like files by sub-agents are sometimes refused; have them return the text and
  save it yourself. A usage-limit stop ends all running in-session sub-agents at once.

## Codex (checked on codex-cli 0.166)
- **In-session sub-agents:** the agent tools, with model and reasoning effort per agent (check the tool definition);
  `wait_agent` waits at most 1 h.
- **Detached workers:** `codex exec -m <model> -c model_reasoning_effort="<effort>" -C <project> -o <reply file>
  "<prompt>"` with `--skip-git-repo-check`; sandbox via `AM_CODEX_FLAGS` (default `-s workspace-write`, no network;
  widen only as the user approves).
- **Waiting:** the `sleep` tool (up to 12 h) is the long wait. `exec_command` yields after ≤ 30 s and empty
  `write_stdin` polls after ≤ 5 min, so polling a running command multiplies calls.
- **Usage:** `usage_report.py codex` reads `~/.codex/sessions/` (model and effort per session). The plan's usage
  reading comes from the user.

## Other frameworks
Fill in the same fields with the user. Without parallel sub-agents, use detached workers if there is a
non-interactive mode, otherwise run agents sequentially, and record it.
