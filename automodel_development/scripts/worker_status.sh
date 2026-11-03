#!/usr/bin/env bash
# One-screen progress of a meta-iteration run by launch_workers.sh. Run from the project root; no model calls.
#   worker_status.sh meta_3                 # print once
#   worker_status.sh meta_3 --wait 5400     # block until the launcher exits, a failure is logged, or 5400 s pass
#                                           # (a cheap watcher: in Claude Code run it in the background; its
#                                           #  completion notice wakes the session)
set -u
META=${1:?usage: worker_status.sh <meta_dir> [--wait seconds]}; META=${META%/}
alive() { [ -n "${1:-}" ] && kill -0 "$1" 2>/dev/null; }
running() { [ -f "$META/.launcher.pid" ] && alive "$(cat "$META/.launcher.pid")"; }
newfail() { [ -s "$META/failed.log" ] && { [ ! -f "$META/.launcher.pid" ] || [ "$META/failed.log" -nt "$META/.launcher.pid" ]; }; }
if [ "${2:-}" = "--wait" ]; then
    end=$(( $(date +%s) + ${3:-3600} ))
    for i in $(seq 1 24); do running && break; sleep 5; done    # give a just-started launcher time to register
    while running && ! newfail && [ "$(date +%s)" -lt "$end" ]; do sleep 5; done
fi
if running; then echo "launcher: RUNNING (pid $(cat "$META/.launcher.pid"))"; else echo "launcher: not running"; fi
[ -f "$META/STOP" ] && echo ">>> STOP requested: no new sessions start"
tail -n 1 "$META/launch.log" 2>/dev/null | grep -q "all agents finished" && echo ">>> ALL AGENTS FINISHED: start the review <<<"
[ -s "$META/failed.log" ] && { echo ">>> FAILURES (fix, then re-run the launcher to continue):"; cat "$META/failed.log"; }
for d in $(ls -d "$META"/agent_* 2>/dev/null | sort -V); do
    s=${d##*_}
    tot=$(awk -v s="$s" '{sub(/#.*/,"")} $1==s{print ($5?$5:"'${AM_ATTEMPTS:-5}'")}' "$META/agents.conf" 2>/dev/null)
    n=0; for a in "$d"/attempt_*; do [ -d "$a" ] && "$META/done_attempt.sh" "$a" >/dev/null 2>&1 && n=$((n+1)); done
    cur=$(ls -d "$d"/attempt_* 2>/dev/null | sort -V | tail -1)
    st=""; [ -n "$cur" ] && [ -f "$cur/.job" ] && st="(job pending)"
    own=""; [ -f "$d/.owner" ] && { alive "$(cat "$d/.owner")" && own="owned by pid $(cat "$d/.owner")" || own="STALE owner marker"; }
    card=$(ls -t "$d"/attempt_*/card.md 2>/dev/null | head -1)
    echo "agent $s: $n/${tot:-?} validated; now $(basename "${cur:-none}") $st $own$([ -s "$d/summary.md" ] && echo '; summary.md written')"
    [ -n "$card" ] && echo "    latest card ($(basename "$(dirname "$card")")): $(head -n 1 "$card" | cut -c1-150)"
    tail -n 1 "$d/sessions.log" 2>/dev/null | sed 's/^/    last: /'
done
