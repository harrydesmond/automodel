# Workers on a cluster

When evaluations run on a cluster, the launcher can run there as well, in a long scheduler job on a compute node, so
workers submit and collect jobs directly, the meta-agent stays local and nothing depends on the user's machine. If the
user's instructions, memory or an earlier project record a working setup, reuse it: verify it with one short job
rather than setting it up again. Otherwise it needs:
- The CLI installed on the cluster; compute nodes that reach the model API and, if workers submit, may submit jobs.
- A tree holding only what workers need (code, data, brief), with no instruction files in or above it unless
  intended; check it matches the local copy before each launch.
- A separate agent home (Claude `CLAUDE_CONFIG_DIR`, Codex `CODEX_HOME`): no personal instructions, memory, skills or
  old sessions, and worker logs stay apart (`usage_report.py --home`, run where that home is). Log it in once, with
  the credential kept owner-only (the CLI's adapter).
- A job script that runs the launcher in the foreground (a backgrounded launcher would end with the job script); its
  scheduler time limit bounds the launcher and its sessions, not the jobs workers submit: a run-wide execution limit
  also needs deadlines on those jobs, set from the remaining allowance, or cancellation from their receipts. Keep the
  credential and the launcher job's scheduler variables out of jobs that workers submit. A requeued job starts on
  fresh processes: its script removes `meta_m/.lock` on restart (the lock records its host, so `--reclaim` elsewhere
  refuses).
- One copy of the run state: while the launcher runs, the cluster tree's `meta_m/`, records, budget counter and
  `tools/` are authoritative, and the local project keeps the plan, `CONTEXT.md` and harness source. Copy the run
  state back (or review on the cluster) only after the launcher has ended, so that the two sides never write the same
  files.
- Watching: `worker_status.sh` checks the launcher's processes, so run it on the launcher's node, one check at a time,
  as a short step inside the launcher's job (Slurm: `srun --jobid=<launcher job> --overlap <skill>/scripts/worker_status.sh
  meta_m`). Never run its `--wait` on a login node: login nodes are for short commands and are rebooted.
