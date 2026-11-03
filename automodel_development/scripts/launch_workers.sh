#!/usr/bin/env bash
# Hybrid/detached automodel workers for one meta-iteration (assets/resources.md §2b).
# Per agent: one fresh non-interactive session per attempt (memory = notes.md, sharing = exchange.md), then a summary
# session, then the optional hook <meta_dir>/after_agent.sh <agent_dir>. Idempotent: re-run after any stop to continue.
#
#   setsid nohup <skill>/scripts/launch_workers.sh meta_3 > meta_3/launch.log 2>&1 < /dev/null &
#   <skill>/scripts/launch_workers.sh meta_3 2 5          # only agents 2 and 5
# Run from the project root. <meta_dir>/agents.conf, one line per agent:
#   <s> <cli: codex|claude> <model> [effort, or - for default] [attempts]          (# comments allowed)
# Also needed: <meta_dir>/COMMON_PROMPT.md and <meta_dir>/agent_<s>/DIRECTION.md.
# Optional: <meta_dir>/done_attempt.sh <attempt_dir> (exit 0 = attempt complete; default: evaluation.md exists and no
# .job marker). Environment: AM_ATTEMPTS (default 5), AM_RETRY_WAIT (s, default 1800), AM_MAX_TRIES (default 8),
# AM_CODEX_FLAGS (default "-s workspace-write"; "--dangerously-bypass-approvals-and-sandbox" if workers need network),
# AM_CLAUDE_FLAGS (default "--permission-mode bypassPermissions").
set -u
META=${1:?usage: launch_workers.sh <meta_dir> [agents...]}; shift
META=${META%/}
[ -f "$META/agents.conf" ] && [ -f "$META/COMMON_PROMPT.md" ] || { echo "need $META/agents.conf and $META/COMMON_PROMPT.md" >&2; exit 1; }
ROOT=$PWD; RETRY_WAIT=${AM_RETRY_WAIT:-1800}; MAX_TRIES=${AM_MAX_TRIES:-8}
if [ -f "$META/.launcher.pid" ] && kill -0 "$(cat "$META/.launcher.pid")" 2>/dev/null; then
    echo "a launcher for $META is already running (pid $(cat "$META/.launcher.pid")); stop it or wait" >&2; exit 1
fi
echo $$ > "$META/.launcher.pid"
trap 'rm -f "$META/.launcher.pid"' EXIT
declare -A CLI MODEL EFFORT NATT
while IFS= read -r line || [ -n "$line" ]; do
    read -r s c m e n _ <<< "${line%%#*}"
    [[ "${s:-}" =~ ^[0-9]+$ ]] || continue
    CLI[$s]=$c; MODEL[$s]=$m; EFFORT[$s]=${e:-}; NATT[$s]=${n:-${AM_ATTEMPTS:-5}}
    [ "${EFFORT[$s]}" = "-" ] && EFFORT[$s]=""
done < "$META/agents.conf"
AGENTS=${*:-$(printf '%s\n' "${!MODEL[@]}" | sort -n | tr '\n' ' ')}
for s in $AGENTS; do [ -n "${MODEL[$s]:-}" ] || { echo "agent $s not in $META/agents.conf" >&2; exit 1; }; done

done_attempt() {
    if [ -x "$META/done_attempt.sh" ]; then "$META/done_attempt.sh" "$1"; else [ -f "$1/evaluation.md" ] && [ ! -f "$1/.job" ]; fi
}

run_session() {  # agent, label, prompt
    local s=$1 lab=$2 p=$3 d=$META/agent_$1 rc
    case ${CLI[$s]} in
        codex) codex exec -m "${MODEL[$s]}" ${EFFORT[$s]:+-c "model_reasoning_effort=\"${EFFORT[$s]}\""} \
                   ${AM_CODEX_FLAGS:--s workspace-write} --skip-git-repo-check -C "$ROOT" -o "$d/.reply_$lab.md" "$p" < /dev/null >> "$d/session_$lab.log" 2>&1 ;;
        claude) claude -p "$p" --model "${MODEL[$s]}" ${EFFORT[$s]:+--effort "${EFFORT[$s]}"} \
                   ${AM_CLAUDE_FLAGS:---permission-mode bypassPermissions} < /dev/null > "$d/.reply_$lab.md" 2>> "$d/session_$lab.log" ;;
        *) echo "agent $s: unknown cli '${CLI[$s]}'" >&2; return 1 ;;
    esac
    rc=$?; echo "$(date '+%F %T') agent $s $lab session exit $rc" >> "$d/sessions.log"
    return $rc
}

fail() {  # agent, message: record and stop this agent
    echo "$(date '+%F %T') agent $1 FAILED: $2" | tee -a "$META/agent_$1/sessions.log" >> "$META/failed.log"; return 1
}

session_until() {  # agent, label, done-test, prompt: retry until done; stop at once on a fast failure (bad model/flag)
    local s=$1 lab=$2 test=$3 p=$4 t t0 rc
    for t in $(seq 1 "$MAX_TRIES"); do
        eval "$test" && return 0
        t0=$(date +%s); run_session "$s" "$lab" "$p"; rc=$?
        eval "$test" && return 0
        [ $rc -ne 0 ] && [ $(( $(date +%s) - t0 )) -lt 60 ] && { fail "$s" "$lab: session failed within 60 s (exit $rc); see $META/agent_$s/session_$lab.log"; return 1; }
        sleep "$RETRY_WAIT"
    done
    fail "$s" "$lab not finished after $MAX_TRIES sessions"
}

agent_loop() {
    local s=$1 d=$META/agent_$1 i a n=${NATT[$1]}
    mkdir -p "$d"
    for i in $(seq 1 "$n"); do
        a=$d/attempt_$i
        session_until "$s" "a$i" "done_attempt '$a'" "You are agent $s of meta-iteration $META of an automodel search; \
project directory $ROOT. Read $META/COMMON_PROMPT.md and $d/DIRECTION.md, then $d/notes.md and the evaluation.md of your \
earlier attempts (if any), and the other agents' $META/agent_*/exchange.md. Carry out ATTEMPT $i ONLY, in $a, as those \
files specify. If $a/.job exists, an evaluation is already running or finished: harvest it as COMMON_PROMPT.md \
describes and never resubmit it. Finish this session only when $a/evaluation.md is written, no job of yours is pending, \
$d/notes.md is updated (<= 300 words: current best, what worked, queue of next hypotheses) and $d/exchange.md lists any \
component worth sharing (file, parameter map, effect). Final reply: at most five lines." || return 1
    done
    session_until "$s" summary "[ -f '$d/summary.md' ]" "You are agent $s of meta-iteration $META of an automodel search; \
project directory $ROOT. All $n attempts in $d are finished. Read $META/COMMON_PROMPT.md (its summary specification), \
$d/DIRECTION.md, $d/notes.md and every $d/attempt_*/evaluation.md and card.md, then write $d/summary.md. No new \
evaluations." || return 1
    echo "$(date '+%F %T') agent $s finished" >> "$d/sessions.log"
    if [ -x "$META/after_agent.sh" ] && [ ! -f "$d/.after_agent.done" ]; then
        "$META/after_agent.sh" "$d" >> "$d/after_agent.log" 2>&1 && touch "$d/.after_agent.done"
        echo "$(date '+%F %T') agent $s after_agent.sh exit $?" >> "$d/sessions.log"
    fi
}

echo "$(date '+%F %T') launching agents: $AGENTS"
rm -f "$META/failed.log"
for s in $AGENTS; do agent_loop "$s" & sleep 20; done
wait
if [ -s "$META/failed.log" ]; then echo "$(date '+%F %T') $META: agents stopped with failures:"; cat "$META/failed.log"
else echo "$(date '+%F %T') $META: all agents finished; start the review"; fi
