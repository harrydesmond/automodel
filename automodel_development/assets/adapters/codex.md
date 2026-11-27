# Codex (CLI checked on 0.167.0; tools vary by session)

Re-check flags and limits with `--help` and the exposed tools when planning, and record what you confirmed in
`CONTEXT.md`. Offer models as concrete names from a verified list.

- **In-session:** use exposed agent tools and limits. Full-history forks may require inherited model/effort; supply
  a fresh brief when overriding them. Check effective capacity before launching S agents.
- **Detached:** `codex exec -m <model> -c 'model_reasoning_effort="<effort>"' -C <project> -o <reply>
  "<prompt>" < /dev/null`. Use `--skip-git-repo-check` outside repositories. Set approved sandbox, write-root and
  network permissions explicitly; project-root access does not isolate agent folders. With the sandbox on
  (`-s workspace-write`, the launcher's default) the network is off and background processes die with the command
  that started them (checked on 0.167): that suits evaluations run in the foreground; cluster submission, local
  background jobs and a meta-agent starting the launcher need the wider permissions the user approves.
- **Residual context:** by default a session also loads `$CODEX_HOME/AGENTS.md`, every `AGENTS.md` from the git root
  down to the working directory, the user's `config.toml` (MCP servers, plugins, memories) and the skills in
  `$CODEX_HOME` (checked on 0.170 with `codex debug prompt-input`, which renders the model-visible prompt without a
  model call). The launcher turns off the user config, memories and project instruction files (`launch_workers.sh`
  header) and passes `WORKER_RULES.md` as developer instructions; the personal `AGENTS.md` and user skills go only
  with a separate `CODEX_HOME` (`cluster.md`), which cuts a worker's fixed prompt by about a third.
- **Waiting:** inspect active tools and instructions. Observed maxima: `sleep` 12 h, `wait_agent` 1 h,
  `exec_command` yield 30 s, empty `write_stdin` poll 5 min. Observed sessions discouraged blocking waits over 60 s;
  workers mostly kept short sleeps despite longer-wait prompts, with almost all repeated input cached. Set cadences
  within applicable limits; assess cost using `resources.md` §3.
- **Usage:** `usage_report.py codex` reads local session logs (`$CODEX_HOME` or `~/.codex`); check coverage against
  launched sessions. Allowance readings come from the user.
- **Login on another machine** (`cluster.md`): `codex login` with `CODEX_HOME` set to the separate worker home
  (`--device-auth` on a machine without a browser), in a terminal rather than through an agent.
