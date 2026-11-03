# Framework profiles

This file names no models, because model line-ups change too often. It defines three **tiers** and, per framework,
the mechanics the meta-agent needs. CLI flags and limits below were checked on the versions named; re-check them with
`--help` or the tool definitions at initialisation and record what you confirmed in `CONTEXT.md` ("Resources").

## Tiers (heavy searches; a light search uses the session's model, or one model for all sub-agents)
- **top**: the strongest reasoning model the framework offers. For the meta-agent and the hardest open-ended directions.
- **strong**: the next model down, capable of open-ended diagnosis and code changes at lower cost. The default for
  sub-agents.
- **economy**: the cheapest model that still edits code, runs tools and follows a fixed protocol reliably. For
  mechanical work.

Binding: list the models the framework offers (sub-agent tool options, CLI `--model` choices, documentation, your own
model), rank them by capability and cost, propose top / strong / economy with their effort levels, and confirm with the
user (say so if the ranking is unclear). Collapse tiers if fewer than three models exist. From then on name the bound
models, never bare tiers. Re-check the binding when planning a meta-iteration if the line-up may have changed.

## Claude Code (checked on 2.1.x)
- **In-session sub-agents:** the Agent tool, with per-agent `model` and `effort`. The tool sets effort only when the
  user or a skill asks; the resource plan the user approves is that request. Use the highest effort only if the user
  asks. Launch all of a meta-iteration's agents in one message, in the background. A stopped agent is resumed with
  SendMessage (its transcript is kept).
- **Detached workers:** `claude -p "<prompt>" --model <model> --effort <low|medium|high|xhigh|max>
  --permission-mode bypassPermissions` (`<skill>/scripts/launch_workers.sh`, cli `claude`). A `-p` session ends when its turn
  ends, so a worker must wait in the foreground and never leave a background job behind.
- **Waiting:** a foreground command can block for at most 10 min, so long waits are a script that blocks ≤ ~9.5 min
  and prints the job's state, repeated. In the interactive session, a background command that returns when the work is
  done (e.g. `<skill>/scripts/worker_status.sh meta_m --wait 5400`) wakes the meta-agent with its completion notice,
  which is the cheapest wait. Prompt-cache entries expire during waits of several minutes, so prefer fewer, longer
  waits.
- **Orchestrator model:** the session's model, chosen by the user (`/model`). Recommend; do not switch it yourself.
- **Usage:** completion notices give per-agent tokens, tool uses and duration (the harness's figures, not billing).
  `<skill>/scripts/usage_report.py claude --cwd <project> --since <time>` reads the session logs (`~/.claude/projects/`),
  workers included. The allowance reading (`/usage`) must come from the user.
- **Known behaviours:** the harness sometimes refuses sub-agents' writes of report-like files (`summary.md`): have them
  return the text and save it yourself. A usage-limit stop ends every running in-session sub-agent at once; resume each
  after the reset with an instruction to harvest pending jobs first.

## Codex (checked on codex-cli 0.166)
- **In-session sub-agents:** the agent tools, with model and reasoning effort settable per agent (check the tool
  definition). `wait_agent` waits at most 1 h.
- **Detached workers:** `codex exec -m <model> -c model_reasoning_effort="<effort>" -C <project> -o <reply file>
  "<prompt>"` with `-s workspace-write` (no network), or `--dangerously-bypass-approvals-and-sandbox` when workers need
  the network (e.g. ssh to a cluster); ask the user which.
- **Waiting:** the `sleep` tool (1 ms to 12 h) is the long wait. `exec_command` yields after ≤ 30 s and empty
  `write_stdin` polls after ≤ 5 min, so polling a running command cannot wait long and only multiplies calls.
- **Orchestrator model:** the session's model, chosen by the user. Recommend; do not switch it yourself.
- **Usage:** `<skill>/scripts/usage_report.py codex --cwd <project> --since <time>` reads `~/.codex/sessions/` (model and
  effort per session included). The plan's usage reading must come from the user.
- **Known behaviours:** very thorough checking (in one run it found scorer bugs that other reviews missed), but process
  inflation unless scope limits are explicit: score-only reruns, sub-agents repurposed as auditors, long hedged prose.
  Give word caps and "no audits" in the prompt.

## Other frameworks
Fill in the same fields with the user at initialisation. Without parallel sub-agents, run the agents as detached
workers if the framework has a non-interactive mode, otherwise sequentially (S = 1 per launch), and record that.
