#!/usr/bin/env bash
# Detached automodel workers for one meta-iteration (assets/detached.md).
# Per agent: one fresh non-interactive session per attempt (memory = notes.md, sharing = exchange.md), then a summary
# session, then the optional hook <meta_dir>/after_agent.sh <agent_dir>. Re-running continues from validated state.
# Summary completion needs the launcher-owned .summary.done receipt; attempt sessions invalidate it.
#
#   setsid nohup <skill>/scripts/launch_workers.sh meta_3 >> meta_3/launch.log 2>&1 < /dev/null &
#   <skill>/scripts/launch_workers.sh meta_3 2 5          # only agents 2 and 5 (when no launcher runs on meta_3)
#   touch meta_3/STOP                                     # no new session or hook starts; running ones finish
#   <skill>/scripts/launch_workers.sh --reclaim meta_3    # after a crash: release the lock once no worker survives
# Run from the project root. Required in <meta_dir>:
#   agents.conf      one line per agent: <s> <cli: codex|claude> <model> [effort or -] [attempts]   (# comments allowed)
#   COMMON_PROMPT.md, agent_<s>/DIRECTION.md
#   done_attempt.sh  executable; exit 0 only when all required variants/controls have validated results or recorded
#                    failures and no job remains pending; otherwise non-zero for recovery. Prose is not evidence.
# Optional: after_agent.sh <agent_dir> (e.g. a refit of the agent's best attempt for the review); hooks submit work only
#   through the harness, which applies the same budget and STOP checks.
#   job_state.sh <attempt_dir>  (phase sessions) exit 0 = the attempt has jobs running, 1 = jobs finished but not yet
#                    collected, anything else = none pending. With it, workers end their session after submitting work
#                    (leaving <attempt_dir>/STATE.md) instead of waiting in-session; the launcher polls the hook (no model
#                    calls) and starts a fresh resume session when the jobs finish. Phase resumptions spend no retry,
#                    except a session that again ends with finished jobs uncollected (e.g. collection keeps failing).
#   WORKER_RULES.md  standing rules for workers: claude appends it to the system prompt, codex gets it as developer
#                    instructions.
# Isolation (AM_ISOLATE=1 default): workers get their context from the brief, not from instruction files: none above the
#   project root, no personal one, and none of the project's own at any depth unless AM_WORKER_PROJECT_MD=1. Claude:
#   also no auto-memory, user settings/plugins, skills or MCP servers. Codex: user config.toml (MCP servers, plugins,
#   features) and memories off; its personal AGENTS.md and user skills live in CODEX_HOME, so point CODEX_HOME at a
#   separate, logged-in home to drop them too. Login is unaffected.
# Usage/rate limits: a session that stops on one spends no retry; the agent waits AM_LIMIT_WAIT s and tries again, for up
#   to AM_LIMIT_MAX_H hours in total, so a run resumes by itself after the limit window resets.
# Several accounts (cli=claude): AM_CLAUDE_TOKENS, a colon-separated list of files each holding one long-lived token
#   (owner-only), in order of preference. Each session reads the first listed file that exists and is not marked
#   limited and passes it as CLAUDE_CODE_OAUTH_TOKEN (never logged; sessions.log names the token's position only). A
#   session stopped by a usage/rate limit marks its token for AM_LIMIT_WAIT s, shared by all agents, and the agent goes
#   on at once with the next unmarked token; with every token marked it waits for the earliest mark to expire. Marks
#   expire, so later sessions return to an earlier token once it has usage again. Files are read at each session, so
#   a token can be added or replaced without a restart. Unset or unreadable: the inherited login.
# Ownership: an atomic lock directory <meta_dir>/.lock (launcher PID, one process group per agent). Workers run in their
#   own process groups; on TERM/INT the launcher stops those groups and releases the lock only once none survives
#   (otherwise the lock stays and failed.log says so). Scheduler jobs are not cancelled by this: harvest or cancel them
#   from their recorded receipts. The lock records its host and boot: a lock from before a reboot is stale whatever its
#   PIDs now point to; one taken on another host (e.g. a launcher running as a cluster job) is checked and reclaimed there.
# Permissions (explicit, approved by the user):
#   AM_CLAUDE_FLAGS  required for cli=claude, e.g. "--permission-mode default --allowedTools Read 'Edit({agent_dir}/**)'
#                    'Edit(tools/**)' 'Bash(python3 harness/submit.py:*)'": in default mode a headless session is refused
#                    anything not allowed; {agent_dir} becomes each worker's own folder (meta_m/agent_s)
#   AM_CODEX_FLAGS   default "-s workspace-write": no network, background jobs die with their command; widen as approved
#   Both are split like shell words: quote an argument that contains spaces; no globbing or substitution.
# Other environment: AM_ATTEMPTS (5), AM_RETRY_WAIT (s, 1800), AM_MAX_TRIES (8), AM_STAGGER (s between agents, 20),
#   AM_LIMIT_WAIT (s, 1200), AM_LIMIT_MAX_H (192), AM_JOB_POLL (s, 120), AM_JOB_WAIT_MAX_H (72), AM_MAX_PHASES (20 per
#   attempt), AM_SESSION_CALLS (50: model calls after which a worker hands over to a fresh session), AM_ISOLATE (1),
#   AM_WORKER_PROJECT_MD (0).
# Exit status: 0 all agents finished, 1 failures (see failed.log), 3 stopped by STOP.
set -u
META=${1:?usage: launch_workers.sh <meta_dir> [agents...]}; shift
META=${META%/}
ROOT=$PWD; RETRY_WAIT=${AM_RETRY_WAIT:-1800}; MAX_TRIES=${AM_MAX_TRIES:-8}; STAGGER=${AM_STAGGER:-20}
LIMIT_WAIT=${AM_LIMIT_WAIT:-1200}; LIMIT_MAX=$(( ${AM_LIMIT_MAX_H:-192} * 3600 ))
JOB_POLL=${AM_JOB_POLL:-120}; JOB_MAX=$(( ${AM_JOB_WAIT_MAX_H:-72} * 3600 )); MAX_PHASES=${AM_MAX_PHASES:-20}
SESSION_CALLS=${AM_SESSION_CALLS:-50}
MANIFEST=$META/launch_manifest.jsonl
TOKENS=(); [ -n "${AM_CLAUDE_TOKENS:-}" ] && IFS=: read -r -a TOKENS <<< "$AM_CLAUDE_TOKENS"
alive() { [ -n "${1:-}" ] && kill -0 "$1" 2>/dev/null; }
LOCK=$META/.lock
groups_alive() { local g; for g in $(cat "$LOCK/groups" 2>/dev/null); do kill -0 -- "-$g" 2>/dev/null && echo "$g"; done; }
here() { echo "$(hostname) $(cat /proc/sys/kernel/random/boot_id 2>/dev/null || echo -)"; }
lock_host() { local w; w=$(cat "$LOCK/host" 2>/dev/null); [ -n "$w" ] || w=$(here); echo "$w"; }   # no record (older lock): local
lock_scope() {  # 0: recorded processes may live here; 1: lock predates a reboot of this host; 2: taken on another host
    local w h; w=$(lock_host); h=$(here); [ "$w" = "$h" ] && return 0; [ "${w%% *}" = "${h%% *}" ] && return 1; return 2; }
if [ "$META" = "--reclaim" ]; then
    META=${1:?usage: launch_workers.sh --reclaim <meta_dir>}; META=${META%/}; LOCK=$META/.lock
    [ -d "$LOCK" ] || { echo "no lock in $META"; exit 0; }
    lock_scope; sc=$?
    [ $sc -eq 2 ] && { echo "lock taken on $(lock_host | cut -d' ' -f1): check its processes and reclaim there (a requeued or ended scheduler job's lock may be removed by hand)" >&2; exit 1; }
    if [ $sc -eq 0 ]; then
        alive "$(cat "$LOCK/launcher" 2>/dev/null)" && { echo "launcher $(cat "$LOCK/launcher") is alive; not reclaiming" >&2; exit 1; }
        live=$(groups_alive); [ -z "$live" ] || { echo "worker process groups still alive: $live; stop them first" >&2; exit 1; }
    fi
    rm -rf "$LOCK"; echo "lock released$([ $sc -eq 1 ] && echo ' (taken before a reboot)'); reconcile recorded jobs (.job receipts) before relaunching"; exit 0
fi

for f in agents.conf COMMON_PROMPT.md; do [ -f "$META/$f" ] || { echo "need $META/$f" >&2; exit 1; }; done
[ -x "$META/done_attempt.sh" ] || { echo "need executable $META/done_attempt.sh (completion validator)" >&2; exit 1; }
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
done

words() { printf '%s' "$1" | xargs -r -n1 printf '%s\n'; }   # shell-style quoting, no globbing or substitution
CF=(); XF=()
if [ -n "${AM_CLAUDE_FLAGS:-}" ]; then w=$(words "$AM_CLAUDE_FLAGS") || { echo "AM_CLAUDE_FLAGS: unbalanced quotes" >&2; exit 1; }; mapfile -t CF <<< "$w"; fi
w=$(words "${AM_CODEX_FLAGS:--s workspace-write}") || { echo "AM_CODEX_FLAGS: unbalanced quotes" >&2; exit 1; }; [ -n "$w" ] && mapfile -t XF <<< "$w"
MABS=$(cd "$META" && pwd)
JOBHOOK=""; [ -x "$META/job_state.sh" ] && JOBHOOK=$MABS/job_state.sh
ISO=(); CISO=()
if [ "${AM_ISOLATE:-1}" = 1 ]; then   # workers: no unrelated instruction files, memory, plugins, skills or MCP
    ex=(); d=$(dirname "$ROOT")
    while :; do
        for n in CLAUDE.md CLAUDE.local.md AGENTS.md; do [ -e "$d/$n" ] && ex+=("$d/$n"); done
        [ "$d" = / ] && break; d=$(dirname "$d")
    done
    ex+=("${CLAUDE_CONFIG_DIR:-$HOME/.claude}/CLAUDE.md")
    [ "${AM_WORKER_PROJECT_MD:-0}" = 1 ] || ex+=("$ROOT/**/CLAUDE.md" "$ROOT/**/CLAUDE.local.md" "$ROOT/**/AGENTS.md")
    js=$(printf '"%s",' "${ex[@]}")
    ISO=(--disable-slash-commands --strict-mcp-config --setting-sources project,local
         --settings "{\"claudeMdExcludes\":[${js%,}],\"autoMemoryEnabled\":false}")
    CISO=(--ignore-user-config --disable memories -c 'project_root_markers=[]')   # project root = $ROOT, not the git root
    [ "${AM_WORKER_PROJECT_MD:-0}" = 1 ] || CISO+=(-c project_doc_max_bytes=0)
fi
if [ -f "$META/WORKER_RULES.md" ]; then
    ISO+=(--append-system-prompt-file "$MABS/WORKER_RULES.md")
    r=$(cat "$META/WORKER_RULES.md"); r=${r//$'\r'/}; r=${r//\\/\\\\}; r=${r//\"/\\\"}; r=${r//$'\t'/\\t}; r=${r//$'\n'/\\n}
    CISO+=(-c "developer_instructions=\"$r\"")   # TOML basic string
fi

if ! mkdir "$LOCK" 2>/dev/null; then
    lock_scope; sc=$?
    if [ $sc -eq 0 ] && alive "$(cat "$LOCK/launcher" 2>/dev/null)"; then echo "a launcher for $META is already running (pid $(cat "$LOCK/launcher"))" >&2
    elif [ $sc -eq 2 ]; then echo "$LOCK was taken on $(lock_host | cut -d' ' -f1): a launcher may be running there" >&2
    else echo "stale lock $LOCK: check for surviving workers and recorded jobs, then run with --reclaim" >&2; fi
    exit 1
fi
here > "$LOCK/host.tmp" && mv "$LOCK/host.tmp" "$LOCK/host"; echo $$ > "$LOCK/launcher"; : > "$LOCK/groups"
PIDS=""
release() {  # stop recorded worker groups (if asked), then release the lock only if none survives
    local sig g i
    for sig in ${1:-}; do for g in $PIDS; do kill "-$sig" -- "-$g" 2>/dev/null; done; [ "$sig" = TERM ] && sleep 2; done
    for i in $(seq 1 10); do [ -z "$(groups_alive)" ] && break; sleep 1; done
    if [ -n "$(groups_alive)" ]; then
        echo "$(date '+%F %T') worker process groups $(groups_alive | tr '\n' ' ')unresolved; lock kept" >> "$META/failed.log"; return 1
    fi
    rm -rf "$LOCK"
}
cleanup() {
    trap '' TERM INT
    echo "$(date '+%F %T') launcher interrupted" >> "$META/failed.log"
    release "TERM KILL"; exit 1
}
trap cleanup TERM INT

log() { echo "$(date '+%F %T') agent $1 $2" >> "$META/agent_$1/sessions.log"; }
manifest() { printf '{"time":"%s","meta":"%s","agent":%s,"label":"%s","cli":"%s","model":"%s","effort":"%s","event":"%s","rc":"%s"}\n' \
    "$(date -u +%FT%TZ)" "$META" "$1" "$2" "${CLI[$1]}" "${MODEL[$1]}" "${EFFORT[$1]}" "$3" "${4:-}" >> "$MANIFEST"; }
fail() { echo "$(date '+%F %T') agent $1 FAILED: $2" | tee -a "$META/agent_$1/sessions.log" >> "$META/failed.log"; return 1; }

run_session() {  # agent, label, prompt
    local s=$1 lab=$2 p=$3 d=$META/agent_$1 rc previous
    rm -f "$d/.summary.done" || return 1
    if [ "$lab" = summary ] && [ -e "$d/summary.md" ]; then
        previous=$(mktemp "$d/summary.previous.XXXXXX") || return 1
        mv -- "$d/summary.md" "$previous" || return 1
    fi
    manifest "$s" "$lab" start
    case ${CLI[$s]} in
        codex) codex exec -m "${MODEL[$s]}" ${EFFORT[$s]:+-c "model_reasoning_effort=\"${EFFORT[$s]}\""} \
                   "${XF[@]}" "${CISO[@]}" --skip-git-repo-check -C "$ROOT" -o "$d/.reply_$lab.md" "$p" \
                   < /dev/null >> "$d/session_$lab.log" 2>&1 ;;
        claude) claude_tok "$( [ "${TI:--2}" -ge 0 ] && cat "${TOKENS[$TI]}" 2>/dev/null)" \
                   -p "$p" --model "${MODEL[$s]}" ${EFFORT[$s]:+--effort "${EFFORT[$s]}"} "${CF[@]//\{agent_dir\}/$d}" "${ISO[@]}" \
                   < /dev/null > "$d/.reply_$lab.md" 2>> "$d/session_$lab.log" ;;
    esac
    rc=$?
    if [ "$lab" = summary ] && [ "$rc" -eq 0 ] && [ -s "$d/summary.md" ]; then
        touch "$d/.summary.done" || rc=1
    fi
    log "$s" "$lab session exit $rc"; manifest "$s" "$lab" end "$rc"
    return $rc
}

token_pick() {  # index of the first readable token file not marked limited; -1 all marked; -2 none listed or readable
    local i u now n=0; now=$(date +%s)
    for i in "${!TOKENS[@]}"; do
        [ -s "${TOKENS[$i]}" ] || continue; n=$(( n + 1 ))
        u=$(cat "$META/.tokens/$i" 2>/dev/null); [ "$now" -ge "${u:-0}" ] 2>/dev/null && { echo "$i"; return 0; }
    done
    [ "$n" -eq 0 ] && echo -2 || echo -1
}

token_mark() {  # index: marked limited for LIMIT_WAIT s, for every agent of this meta-iteration
    mkdir -p "$META/.tokens" && echo $(( $(date +%s) + LIMIT_WAIT )) > "$META/.tokens/$1.$BASHPID" &&
        mv -f "$META/.tokens/$1.$BASHPID" "$META/.tokens/$1"
}

token_wait() {  # seconds until the earliest mark expires (1 to LIMIT_WAIT)
    local i u w=$LIMIT_WAIT now; now=$(date +%s)
    for i in "${!TOKENS[@]}"; do
        u=$(cat "$META/.tokens/$i" 2>/dev/null) || continue; [ $(( u - now )) -lt "$w" ] && w=$(( u - now ))
    done
    [ "$w" -lt 1 ] && w=1; echo "$w"
}

claude_tok() {  # token (may be empty) then claude's arguments: the token goes to claude's environment, not its argv
    local t=$1; shift
    if [ -n "$t" ]; then CLAUDE_CODE_OAUTH_TOKEN=$t command claude "$@"; else command claude "$@"; fi
}

limit_hit() {  # agent, label, log offset, rc: did this session stop on a usage or rate limit?
    local out
    out=$(tail -c +$(( $3 + 1 )) "$META/agent_$1/session_$2.log" 2>/dev/null | head -c 20000
          cat "$META/agent_$1/.reply_$2.md" 2>/dev/null | head -c 20000)
    echo "$out" | grep -qiE "hit your [a-z0-9 -]{0,20}limit" && return 0
    [ "$4" -ne 0 ] && echo "$out" | grep -qiE "usage limit|rate_limit|rate limit|HTTP 429" && return 0
    return 1
}

session_until() {  # agent, label, done-test, prompt[, resume prompt, attempt dir]: 0 done, 1 failed, 3 stopped
    local s=$1 lab=$2 test=$3 p=$4 rp=${5:-} a=${6:-} t=1 rc t0 off lf waited=0 phases=0 jw st q unc=0 w nt lti=-2
    while [ "$t" -le "$MAX_TRIES" ]; do
        eval "$test" && return 0
        [ -f "$META/STOP" ] && { log "$s" "$lab not started: STOP"; return 3; }
        TI=-2
        if [ "${#TOKENS[@]}" -gt 0 ] && [ "${CLI[$s]}" = claude ]; then                       # several accounts
            TI=$(token_pick)
            if [ "$TI" -eq -1 ] && [ "$waited" -lt "$LIMIT_MAX" ]; then
                w=$(token_wait); log "$s" "$lab: every token marked limited; waiting ${w}s"
                sleep "$w"; waited=$(( waited + w )); continue
            fi
            [ "$TI" -eq -1 ] && TI=0
            [ "$TI" != "$lti" ] && [ "$TI" -ge 0 ] && log "$s" "$lab uses token $(( TI + 1 )) of ${#TOKENS[@]}"; lti=$TI
        fi
        lf=$META/agent_$s/session_$lab.log; off=$(stat -c %s "$lf" 2>/dev/null || echo 0); t0=$(date +%s)
        q=$p; [ -n "$rp" ] && [ -f "$a/STATE.md" ] && q=$rp
        run_session "$s" "$lab" "$q"; rc=$?; st=2
        eval "$test" && return 0
        if limit_hit "$s" "$lab" "$off" "$rc" && [ "$waited" -lt "$LIMIT_MAX" ]; then          # no retry spent
            if [ "$TI" -ge 0 ]; then                                                          # mark it, try the next
                token_mark "$TI"; nt=$(token_pick)
                [ "$nt" -ge 0 ] && { log "$s" "$lab stopped by a usage/rate limit on token $(( TI + 1 )); continuing with token $(( nt + 1 ))"; continue; }
                w=$(token_wait); log "$s" "$lab stopped by a usage/rate limit on token $(( TI + 1 )); every token marked limited; waiting ${w}s"
                sleep "$w"; waited=$(( waited + w )); continue
            fi
            log "$s" "$lab stopped by a usage/rate limit; waiting ${LIMIT_WAIT}s"
            sleep "$LIMIT_WAIT"; waited=$(( waited + LIMIT_WAIT )); continue
        fi
        if [ -n "$JOBHOOK" ] && [ -n "$a" ] && [ "$phases" -lt "$MAX_PHASES" ]; then          # phase boundary?
            jw=0; "$JOBHOOK" "$a" >/dev/null 2>&1; st=$?
            [ "$st" -eq 0 ] && log "$s" "$lab waiting for jobs of $a"
            while [ "$st" -eq 0 ] && [ "$jw" -lt "$JOB_MAX" ]; do
                [ -f "$META/STOP" ] && { log "$s" "$lab: STOP while jobs run; not resuming"; return 3; }
                sleep "$JOB_POLL"; jw=$(( jw + JOB_POLL )); "$JOBHOOK" "$a" >/dev/null 2>&1; st=$?
            done
            if [ "$st" -eq 1 ] && [ "$jw" -eq 0 ]; then unc=$(( unc + 1 )); else unc=0; fi   # ended with results uncollected
            if [ "$st" -eq 1 ] && [ "$unc" -le 1 ]; then
                phases=$(( phases + 1 )); log "$s" "$lab resumes after jobs (phase $phases)"; continue
            fi
            [ "$st" -eq 1 ] && log "$s" "$lab ended again with finished jobs uncollected: counts as a retry"
        fi
        if [ -n "$a" ] && [ "$rc" -eq 0 ] && [ "$st" -gt 1 ] && [ "$phases" -lt "$MAX_PHASES" ] &&
           [ "$(stat -c %Y "$a/STATE.md" 2>/dev/null || echo 0)" -ge "$t0" ]; then      # handed over on purpose, no job pending
            phases=$(( phases + 1 )); log "$s" "$lab handed over to a fresh session (phase $phases)"; continue
        fi
        # a quick failure whose own output names a bad model or flag will not fix itself; anything else is retried
        if [ $rc -ne 0 ] && [ $(( $(date +%s) - t0 )) -lt 120 ] && tail -c +$((off + 1)) "$lf" 2>/dev/null | head -n 40 |
           grep -qiE "model.{0,40}(not found|does not exist|not supported|unknown|invalid)|unknown (option|argument|flag)|unexpected argument"; then
            fail "$s" "$lab: configuration error (exit $rc); see $META/agent_$s/session_$lab.log"; return 1
        fi
        [ "$t" -lt "$MAX_TRIES" ] && sleep "$RETRY_WAIT"
        t=$(( t + 1 ))
    done
    fail "$s" "$lab not complete after $MAX_TRIES sessions"
}

agent_loop() {
    local s=$1 d=$META/agent_$1 i a n=${NATT[$1]} rc
    mkdir -p "$d"
    for i in $(seq 1 "$n"); do
        a=$d/attempt_$i
        fin="Count every fit against the stated budget. If $a/.job exists, an evaluation is already running or finished: \
harvest it as COMMON_PROMPT.md describes and never resubmit it. If $META/STOP appears, submit nothing new. Finish only \
when $a holds a complete result (the harness's validator passes), no job of yours is pending, $d/notes.md is updated \
(<= 300 words: current best with its record IDs, what worked, assumptions, unresolved failures, queue of next \
hypotheses) and $d/exchange.md lists any component worth \
sharing (file, parameter map, effect). If this session grows long (about $SESSION_CALLS model calls) before the attempt is \
complete, write $a/STATE.md (<= 150 words: what is done, what to do next) and end the session; a fresh session continues \
from it. Final reply: at most three lines."
        ph=""; [ -n "$JOBHOOK" ] && ph=" Do not wait for cluster jobs in this session: once you have submitted work and \
nothing else useful remains until it finishes, write $a/STATE.md (<= 150 words: what is pending, how to collect it, what \
to do next) and end the session; a fresh session continues when the jobs finish."
        session_until "$s" "a$i" "'$META/done_attempt.sh' '$a'" "You are agent $s of meta-iteration $META of an automodel search; \
project directory $ROOT. Read $META/COMMON_PROMPT.md and $d/DIRECTION.md, then $d/notes.md and the earlier records it points to, and the other agents' $META/agent_*/exchange.md. Complete attempt $i in $a, including assigned variants and controls in their declared paths; \
start no later numbered attempt. $fin$ph" "You are agent $s of meta-iteration $META of an automodel search; project \
directory $ROOT. Resume attempt $i in $a: read $META/COMMON_PROMPT.md, $d/DIRECTION.md and $a/STATE.md (left by your \
previous session; it is your memory), collect any finished jobs, then continue from there. Start no later numbered \
attempt. $fin$ph" "$a"
        rc=$?; [ $rc -ne 0 ] && return $rc
    done
    session_until "$s" summary "[ -s '$d/summary.md' ] && [ -f '$d/.summary.done' ]" "You are agent $s of meta-iteration $META of an automodel search; \
project directory $ROOT. All $n attempts in $d are finished. Read $META/COMMON_PROMPT.md (its summary specification), \
$d/DIRECTION.md, $d/notes.md and every attempt's record, then write $d/summary.md. No new evaluations."
    rc=$?; [ $rc -ne 0 ] && return $rc
    if [ -x "$META/after_agent.sh" ] && [ ! -f "$d/.after_agent.done" ]; then
        [ -f "$META/STOP" ] && { log "$s" "after_agent.sh not started: STOP"; return 3; }
        "$META/after_agent.sh" "$d" >> "$d/after_agent.log" 2>&1; rc=$?
        log "$s" "after_agent.sh exit $rc"
        [ $rc -eq 0 ] || { fail "$s" "after_agent.sh exit $rc"; return 1; }
        touch "$d/.after_agent.done"
    fi
    log "$s" "finished"
}

echo "$(date '+%F %T') launching agents: $AGENTS"
rm -f "$META/failed.log"
set +m
BOOT="$(declare -p META ROOT RETRY_WAIT MAX_TRIES LIMIT_WAIT LIMIT_MAX JOB_POLL JOB_MAX MAX_PHASES SESSION_CALLS JOBHOOK ISO CISO CF XF MANIFEST CLI MODEL EFFORT NATT TOKENS)
$(declare -f log manifest fail run_session token_pick token_mark token_wait claude_tok limit_hit session_until agent_loop)"
for s in $AGENTS; do
    setsid bash -c "$BOOT"$'\n''agent_loop "$1"' automodel-worker "$s" &
    PIDS="$PIDS $!"; echo "$!" >> "$LOCK/groups"; sleep "$STAGGER"
done
status=0
for p in $PIDS; do wait "$p"; rc=$?; [ $rc -gt $status ] && status=$rc; done
[ -s "$META/failed.log" ] && status=1
release "" || status=1
case $status in
    0) echo "$(date '+%F %T') $META: all agents finished; start the review" ;;
    3) echo "$(date '+%F %T') $META: stopped by $META/STOP; completed attempts are kept" ;;
    *) echo "$(date '+%F %T') $META: agents stopped with failures:"; cat "$META/failed.log"; status=1 ;;
esac
exit $status
