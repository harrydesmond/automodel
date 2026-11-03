#!/usr/bin/env bash
# One-screen progress of a meta-iteration run by launch_workers.sh. Run from the project root.
#   worker_status.sh meta_3                 # print once
#   worker_status.sh meta_3 --wait 5400     # block until the launcher exits or 5400 s pass, then print
#                                           # (Claude Code: run in the background; its completion notice wakes you)
set -u
META=${1:?usage: worker_status.sh <meta_dir> [--wait seconds]}; META=${META%/}
running() { [ -f "$META/.launcher.pid" ] && kill -0 "$(cat "$META/.launcher.pid")" 2>/dev/null; }
if [ "${2:-}" = "--wait" ]; then
    end=$(( $(date +%s) + ${3:-3600} ))
    while running && [ "$(date +%s)" -lt "$end" ]; do sleep 60; done
fi
if running; then echo "launcher: RUNNING (pid $(cat "$META/.launcher.pid"))"
else echo "launcher: not running"; fi
tail -n 1 "$META/launch.log" 2>/dev/null | grep -q "all agents finished" && echo ">>> ALL AGENTS FINISHED: start the review <<<"
[ -s "$META/failed.log" ] && { echo ">>> FAILURES (fix, then re-run the launcher to continue):"; cat "$META/failed.log"; }
for d in $(ls -d "$META"/agent_* 2>/dev/null | sort -V); do
    s=${d##*_}
    tot=$(awk -v s="$s" '$1==s{print ($5?$5:"'${AM_ATTEMPTS:-5}'")}' "$META/agents.conf" 2>/dev/null)
    n=$(ls "$d"/attempt_*/evaluation.md 2>/dev/null | wc -l)
    cur=$(ls -d "$d"/attempt_* 2>/dev/null | sort -V | tail -1)
    st=""; [ -n "$cur" ] && [ -f "$cur/.job" ] && st="(job pending)"
    card=$(ls -t "$d"/attempt_*/card.md 2>/dev/null | head -1)
    echo "agent $s: $n/${tot:-?} evaluated; now $(basename "${cur:-none}") $st$([ -f "$d/summary.md" ] && echo '; summary.md written')"
    [ -n "$card" ] && echo "    latest card ($(basename "$(dirname "$card")")): $(head -n 1 "$card" | cut -c1-150)"
    tail -n 1 "$d/sessions.log" 2>/dev/null | sed 's/^/    last: /'
done
