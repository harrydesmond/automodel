#!/usr/bin/env bash
# One-screen progress of a meta-iteration run by launch_workers.sh. Run from the project root; no model calls.
#   worker_status.sh meta_3                 # print once
#   worker_status.sh meta_3 --wait 5400     # block until the launcher exits, a failure is logged, or 5400 s pass;
#                                           # start it after launch registration (returns at once if none runs)
#                                           # (a cheap watcher: in Claude Code run it in the background; its
#                                           #  completion notice wakes the session)
set -u
META=${1:?usage: worker_status.sh <meta_dir> [--wait seconds]}; META=${META%/}
alive() { [ -n "${1:-}" ] && kill -0 "$1" 2>/dev/null; }
LOCK=$META/.lock
running() { alive "$(cat "$LOCK/launcher" 2>/dev/null)"; }
newfail() { [ -s "$META/failed.log" ] && [ "$META/failed.log" -nt "$LOCK/groups" ]; }
if [ "${2:-}" = "--wait" ]; then        # start this after the launcher has registered; returns at once if none runs
    wait_s=${3:-3600}
    [[ "$wait_s" =~ ^[0-9]+$ ]] || { echo "wait seconds must be a non-negative integer" >&2; exit 2; }
    end=$(( $(date +%s) + wait_s ))
    while running && ! newfail; do
        left=$(( end - $(date +%s) )); [ "$left" -gt 0 ] || break
        sleep "$(( left < 5 ? left : 5 ))"
    done
fi
if running; then echo "launcher: RUNNING (pid $(cat "$LOCK/launcher"))"
elif [ -d "$LOCK" ]; then
    live=""; for g in $(cat "$LOCK/groups" 2>/dev/null); do kill -0 -- "-$g" 2>/dev/null && live="$live $g"; done
    echo "launcher: not running; STALE LOCK (live worker groups:${live:- none}); reclaim with launch_workers.sh --reclaim $META"
else echo "launcher: not running"; fi
[ -f "$META/STOP" ] && echo ">>> STOP requested: no new sessions start"
tail -n 1 "$META/launch.log" 2>/dev/null | grep -q "all agents finished" && echo ">>> ALL AGENTS FINISHED: start the review <<<"
[ -s "$META/failed.log" ] && { echo ">>> FAILURES (fix, then re-run the launcher to continue):"; cat "$META/failed.log"; }
for d in $(ls -d "$META"/agent_* 2>/dev/null | sort -V); do
    s=${d##*_}
    tot=$(awk -v s="$s" '{sub(/#.*/,"")} $1==s{print ($5?$5:"'${AM_ATTEMPTS:-5}'")}' "$META/agents.conf" 2>/dev/null)
    n=0; for a in "$d"/attempt_*; do [ -d "$a" ] && "$META/done_attempt.sh" "$a" >/dev/null 2>&1 && n=$((n+1)); done
    cur=$(ls -d "$d"/attempt_* 2>/dev/null | sort -V | tail -1)
    st=""; [ -n "$cur" ] && [ -f "$cur/.job" ] && st="(job pending)"
    card=$(ls -t "$d"/attempt_*/card.md 2>/dev/null | head -1)
    echo "agent $s: $n/${tot:-?} validated; now $(basename "${cur:-none}") $st$([ -s "$d/summary.md" ] && echo '; summary.md written')"
    [ -n "$card" ] && echo "    latest card ($(basename "$(dirname "$card")")): $(head -n 1 "$card" | cut -c1-150)"
    tail -n 1 "$d/sessions.log" 2>/dev/null | sed 's/^/    last: /'
done
