---
type: llm
focus: trace
weight: 1
---

walkthrough.md: Releases the stale lock only after confirming that no recorded launcher or worker process is alive, and allows for PIDs recorded before the reboot now belonging to unrelated processes.
