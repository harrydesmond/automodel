#!/usr/bin/env bash
# Detached automodel workers for one meta-iteration (assets/resources.md §2, hybrid mode).
# Per agent: one fresh non-interactive session per attempt (memory = notes.md, sharing = exchange.md), then a summary
# session, then the optional hook <meta_dir>/after_agent.sh <agent_dir>. Re-running continues from validated state.
#
#   setsid nohup <skill>/scripts/launch_workers.sh meta_3 > meta_3/launch.log 2>&1 < /dev/null &
#   <skill>/scripts/launch_workers.sh meta_3 2 5          # only agents 2 and 5 (when no launcher runs on meta_3)
#   touch meta_3/STOP                                     # no new sessions start; running ones finish
# Run from the project root. Required in <meta_dir>:
#   agents.conf      one line per agent: <s> <cli: codex|claude> <model> [effort or -] [attempts]   (# comments allowed)
#   COMMON_PROMPT.md, agent_<s>/DIRECTION.md
#   done_attempt.sh  executable; exit 0 once the harness has recorded <attempt_dir>'s outcome (a valid result, or a
#                    failure with its reason); non-zero if nothing usable is recorded (then the session is retried).
#                    Prose files are not evidence.
# Optional: after_agent.sh <agent_dir> (e.g. a refit of the agent's best attempt for the review).
# Permissions (explicit, approved by the user):
#   AM_CLAUDE_FLAGS  required for cli=claude, e.g. "--permission-mode acceptEdits --allowedTools Bash(python3:*)"
#   AM_CODEX_FLAGS   default "-s workspace-write" (no network); widen only as approved
# Other environment: AM_ATTEMPTS (5), AM_RETRY_WAIT (s, 1800), AM_MAX_TRIES (8), AM_STAGGER (s between agents, 20).
# Exit status: 0 all agents finished, 1 failures (see failed.log), 3 stopped by STOP.
set -u
META=${1:?usage: launch_workers.sh <meta_dir> [agents...]}; shift
META=${META%/}
for f in agents.conf COMMON_PROMPT.md; do [ -f "$META/$f" ] || { echo "need $META/$f" >&2; exit 1; }; done
[ -x "$META/done_attempt.sh" ] || { echo "need executable $META/done_attempt.sh (completion validator)" >&2; exit 1; }
ROOT=$PWD; RETRY_WAIT=${AM_RETRY_WAIT:-1800}; MAX_TRIES=${AM_MAX_TRIES:-8}; STAGGER=${AM_STAGGER:-20}
MANIFEST=$META/launch_manifest.jsonl
alive() { [ -n "${1:-}" ] && kill -0 "$1" 2>/dev/null; }
if [ -f "$META/.launcher.pid" ] && alive "$(cat "$META/.launcher.pid")"; then
    echo "a launcher for $META is already running (pid $(cat "$META/.launcher.pid"))" >&2; exit 1
fi

declare -A CLI MODEL EFFORT NATT
while IFS= read -r line || [ -n "$line" ]; do
    read -r s c m e n _ <<< "${line%%#*}"
    [[ "${s:-}" =~ ^[0-9]+$ ]] || continue
    CLI[$s]=$c; MODEL[$s]=$m; EFFORT[$s]=${e:-}; NATT[$s]=${n:-${AM_ATTEMPTS:-5}}
    [ "${EFFORT[$s]}" = "-" ] && EFFORT[$s]=""
done < "$META/agents.conf"
AGENTS=${*:-$(printf '%s\n' "${!MODEL[@]}" | sort -n | tr '\n' ' ')}
for s in $AGENTS; do
    [ -n "${MODEL[$s]:-}" ] || { echo "agent $s not in $META/agents.conf" >&2; exit 1; }
    case ${CLI[$s]} in
        claude) [ -n "${AM_CLAUDE_FLAGS:-}" ] || { echo "cli=claude needs AM_CLAUDE_FLAGS (approved permission settings)" >&2; exit 1; } ;;
        codex) ;;
        *) echo "agent $s: unknown cli '${CLI[$s]}'" >&2; exit 1 ;;
    esac
    o=$META/agent_$s/.owner
    if [ -f "$o" ] && alive "$(cat "$o")"; then echo "agent $s is owned by live pid $(cat "$o")" >&2; exit 1; fi
done

echo $$ > "$META/.launcher.pid"
PIDS=""
killtree() { local c; for c in $(pgrep -P "$1"); do killtree "$c" "$2"; done; kill "-$2" "$1" 2>/dev/null; }
cleanup() {  # on TERM/INT: stop every process the workers started, then release the markers
    trap - TERM INT
    for p in $PIDS; do killtree "$p" TERM; done
    sleep 2
    for p in $PIDS; do killtree "$p" KILL; done
    for s in $AGENTS; do rm -f "$META/agent_$s/.owner"; done
    rm -f "$META/.launcher.pid"
    echo "$(date '+%F %T') launcher interrupted; workers stopped" >> "$META/failed.log"
    exit 1
}
trap cleanup TERM INT

log() { echo "$(date '+%F %T') agent $1 $2" >> "$META/agent_$1/sessions.log"; }
manifest() { printf '{"time":"%s","meta":"%s","agent":%s,"label":"%s","cli":"%s","model":"%s","effort":"%s","event":"%s","rc":"%s"}\n' \
    "$(date -u +%FT%TZ)" "$META" "$1" "$2" "${CLI[$1]}" "${MODEL[$1]}" "${EFFORT[$1]}" "$3" "${4:-}" >> "$MANIFEST"; }
fail() { echo "$(date '+%F %T') agent $1 FAILED: $2" | tee -a "$META/agent_$1/sessions.log" >> "$META/failed.log"; return 1; }

run_session() {  # agent, label, prompt
    local s=$1 lab=$2 p=$3 d=$META/agent_$1 rc
    manifest "$s" "$lab" start
    case ${CLI[$s]} in
        codex) codex exec -m "${MODEL[$s]}" ${EFFORT[$s]:+-c "model_reasoning_effort=\"${EFFORT[$s]}\""} \
                   ${AM_CODEX_FLAGS:--s workspace-write} --skip-git-repo-check -C "$ROOT" -o "$d/.reply_$lab.md" "$p" \
                   < /dev/null >> "$d/session_$lab.log" 2>&1 ;;
        claude) claude -p "$p" --model "${MODEL[$s]}" ${EFFORT[$s]:+--effort "${EFFORT[$s]}"} $AM_CLAUDE_FLAGS \
                   < /dev/null > "$d/.reply_$lab.md" 2>> "$d/session_$lab.log" ;;
    esac
    rc=$?; log "$s" "$lab session exit $rc"; manifest "$s" "$lab" end "$rc"
    return $rc
}

session_until() {  # agent, label, done-test, prompt: retry until the test passes; 0 done, 1 failed, 3 stopped
    local s=$1 lab=$2 test=$3 p=$4 t rc t0 off lf
    for t in $(seq 1 "$MAX_TRIES"); do
        eval "$test" && return 0
        [ -f "$META/STOP" ] && { log "$s" "$lab not started: STOP"; return 3; }
        lf=$META/agent_$s/session_$lab.log; off=$(stat -c %s "$lf" 2>/dev/null || echo 0); t0=$(date +%s)
        run_session "$s" "$lab" "$p"; rc=$?
        eval "$test" && return 0
        # a quick failure whose own output names a bad model or flag will not fix itself; anything else is retried
        if [ $rc -ne 0 ] && [ $(( $(date +%s) - t0 )) -lt 120 ] && tail -c +$((off + 1)) "$lf" 2>/dev/null | head -n 40 |
           grep -qiE "model.{0,40}(not found|does not exist|not supported|unknown|invalid)|unknown (option|argument|flag)|unexpected argument"; then
            fail "$s" "$lab: configuration error (exit $rc); see $META/agent_$s/session_$lab.log"; return 1
        fi
        [ "$t" -lt "$MAX_TRIES" ] && sleep "$RETRY_WAIT"
    done
    fail "$s" "$lab not complete after $MAX_TRIES sessions"
}

agent_loop() {
    local s=$1 d=$META/agent_$1 i a n=${NATT[$1]} rc
    mkdir -p "$d"; echo "$BASHPID" > "$d/.owner"
    for i in $(seq 1 "$n"); do
        a=$d/attempt_$i
        session_until "$s" "a$i" "'$META/done_attempt.sh' '$a'" "You are agent $s of meta-iteration $META of an automodel search; \
project directory $ROOT. Read $META/COMMON_PROMPT.md and $d/DIRECTION.md, then $d/notes.md and the records of your \
earlier attempts (if any), and the other agents' $META/agent_*/exchange.md. Carry out ATTEMPT $i ONLY, in $a, as those \
files specify, within the evaluation budget they state. If $a/.job exists, an evaluation is already running or finished: \
harvest it as COMMON_PROMPT.md describes and never resubmit it. If $META/STOP appears, submit nothing new. Finish only \
when $a holds a complete result (the harness's validator passes), no job of yours is pending, $d/notes.md is updated \
(<= 300 words: current best, what worked, queue of next hypotheses) and $d/exchange.md lists any component worth \
sharing (file, parameter map, effect). Final reply: at most five lines."
        rc=$?; [ $rc -ne 0 ] && { rm -f "$d/.owner"; return $rc; }
    done
    session_until "$s" summary "[ -s '$d/summary.md' ]" "You are agent $s of meta-iteration $META of an automodel search; \
project directory $ROOT. All $n attempts in $d are finished. Read $META/COMMON_PROMPT.md (its summary specification), \
$d/DIRECTION.md, $d/notes.md and every attempt's record, then write $d/summary.md. No new evaluations."
    rc=$?; [ $rc -ne 0 ] && { rm -f "$d/.owner"; return $rc; }
    if [ -x "$META/after_agent.sh" ] && [ ! -f "$d/.after_agent.done" ]; then
        "$META/after_agent.sh" "$d" >> "$d/after_agent.log" 2>&1; rc=$?
        log "$s" "after_agent.sh exit $rc"
        [ $rc -eq 0 ] || { fail "$s" "after_agent.sh exit $rc"; rm -f "$d/.owner"; return 1; }
        touch "$d/.after_agent.done"
    fi
    log "$s" "finished"; rm -f "$d/.owner"
}

echo "$(date '+%F %T') launching agents: $AGENTS"
rm -f "$META/failed.log"
for s in $AGENTS; do agent_loop "$s" & PIDS="$PIDS $!"; sleep "$STAGGER"; done
status=0
for p in $PIDS; do wait "$p"; rc=$?; [ $rc -gt $status ] && status=$rc; done
[ -s "$META/failed.log" ] && status=1
rm -f "$META/.launcher.pid"
case $status in
    0) echo "$(date '+%F %T') $META: all agents finished; start the review" ;;
    3) echo "$(date '+%F %T') $META: stopped by $META/STOP; completed attempts are kept" ;;
    *) echo "$(date '+%F %T') $META: agents stopped with failures:"; cat "$META/failed.log"; status=1 ;;
esac
exit $status
