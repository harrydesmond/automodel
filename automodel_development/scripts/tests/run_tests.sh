#!/usr/bin/env bash
# Deterministic tests of launch_workers.sh, worker_status.sh and usage_report.py (no model calls, no real jobs).
#   bash <skill>/scripts/tests/run_tests.sh
set -u
HERE=$(cd "$(dirname "$0")" && pwd); S=$HERE/..; T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir -p "$T/bin"; cp "$HERE/fake_codex" "$T/bin/codex"; chmod +x "$T/bin/codex"; export PATH="$T/bin:$PATH"
export AM_RETRY_WAIT=0 AM_MAX_TRIES=2 AM_STAGGER=0
pass=0; failn=0
check() { if eval "$2"; then pass=$((pass+1)); echo "ok   $1"; else failn=$((failn+1)); echo "FAIL $1"; fi; }
setup() {  # fresh project with meta_1, two agents, validator requiring result.json status ok
  rm -rf "$T/p"; mkdir -p "$T/p/meta_1/agent_1" "$T/p/meta_1/agent_2"; cd "$T/p"
  printf '1 codex m low 2\n2 codex m low 2' > meta_1/agents.conf; echo spec > meta_1/COMMON_PROMPT.md
  echo dir | tee meta_1/agent_1/DIRECTION.md > meta_1/agent_2/DIRECTION.md
  printf '#!/bin/sh\ngrep -q "\\"status\\":\\"ok\\"" "$1/result.json" 2>/dev/null\n' > meta_1/done_attempt.sh; chmod +x meta_1/done_attempt.sh
}
run() { bash "$S/launch_workers.sh" meta_1 "$@" > meta_1/launch.log 2>&1; echo $?; }

setup; rm meta_1/done_attempt.sh; check "refuses to start without a completion validator" '[ "$(run)" = 1 ]'
setup; rc=$(run); check "normal run: exit 0, all attempts and summaries" '[ "$rc" = 0 ] && [ -s meta_1/agent_2/summary.md ] && [ -f meta_1/agent_1/attempt_2/result.json ]'
check "manifest records start/end of every session" '[ "$(grep -c "\"event\":\"end\"" meta_1/launch_manifest.jsonl)" = 6 ]'
check "status counts validated attempts" 'bash "$S/worker_status.sh" meta_1 | grep -q "agent 1: 2/2 validated"'
setup
mkdir -p meta_1/agent_1/attempt_1 meta_1/agent_1/attempt_1b
for a in attempt_1 attempt_1b; do echo '{"status":"ok"}' > "meta_1/agent_1/$a/result.json"; done
check "status counts numbered attempts, not their variants" 'bash "$S/worker_status.sh" meta_1 | grep -q "agent 1: 1/2 validated"'
setup
for i in 1 2; do mkdir -p "meta_1/agent_1/attempt_$i"; echo '{"status":"ok"}' > "meta_1/agent_1/attempt_$i/result.json"; done
echo stale > meta_1/agent_1/summary.md
rc=$(run 1)
check "stale summary triggers a final summary session" '[ "$rc" = 0 ] && [ -f meta_1/agent_1/.summary.done ] && [ "$(grep -c "session exit" meta_1/agent_1/sessions.log)" = 1 ] && grep -q stale meta_1/agent_1/summary.previous.*'
setup
for i in 1 2; do mkdir -p "meta_1/agent_1/attempt_$i"; echo '{"status":"ok"}' > "meta_1/agent_1/attempt_$i/result.json"; done
echo stale > meta_1/agent_1/summary.md
rc=$(FAKE_MODE=empty run 1)
check "stale summary cannot satisfy an empty final-summary session" '[ "$rc" = 1 ] && [ ! -f meta_1/agent_1/.summary.done ]'
setup; rc=$(FAKE_MODE=empty run); check "empty outputs are not success (exit 1)" '[ "$rc" = 1 ] && grep -q FAILED meta_1/failed.log'
setup; rc=$(FAKE_MODE=badmodel run); check "configuration error fails at once" '[ "$rc" = 1 ] && [ "$(grep -c "session exit" meta_1/agent_1/sessions.log)" = 1 ]'
setup; rc=$(FAKE_MODE=flaky FAKE_COUNTER=$T/cnt run 1); check "transient failure is retried" '[ "$rc" = 0 ]'; rm -f "$T/cnt"
setup; printf '#!/bin/sh\nexit 17\n' > meta_1/after_agent.sh; chmod +x meta_1/after_agent.sh; rc=$(run)
check "failing after_agent hook fails the run" '[ "$rc" = 1 ] && grep -q "after_agent.sh exit 17" meta_1/failed.log'
setup; touch meta_1/STOP; rc=$(run); check "STOP: nothing starts, exit 3" '[ "$rc" = 3 ] && [ ! -d meta_1/agent_1/attempt_1 ]'
setup; FAKE_MODE=hang bash "$S/launch_workers.sh" meta_1 > meta_1/launch.log 2>&1 & L=$!; sleep 2
check "second launcher refused while one runs" '[ "$(run)" = 1 ]'
kill -TERM $L; wait $L 2>/dev/null; sleep 1
check "launcher TERM stops its workers and releases the lock" '! pgrep -x sleep -a 2>/dev/null | grep -qx "[0-9]* sleep 3187" && [ ! -d meta_1/.lock ]'
setup; export HB=$T/hb; FAKE_MODE=stubborn bash "$S/launch_workers.sh" meta_1 1 > meta_1/launch.log 2>&1 & L=$!; sleep 2
kill -TERM $L; wait $L 2>/dev/null; sleep 1; h1=$(cat "$HB"); sleep 1; h2=$(cat "$HB")
check "TERM-ignoring descendant is stopped (heartbeat ends)" '[ "$h1" = "$h2" ] && [ ! -d meta_1/.lock ]'
setup; ( FAKE_MODE=hang bash "$S/launch_workers.sh" meta_1 > meta_1/l1.log 2>&1 & FAKE_MODE=hang bash "$S/launch_workers.sh" meta_1 > meta_1/l2.log 2>&1 & wait ) & B=$!
sleep 3; n=$(grep -c "a1 start" meta_1/launch_manifest.jsonl 2>/dev/null || echo 0); nl=$(grep -l "already running" meta_1/l1.log meta_1/l2.log | wc -l)
check "simultaneous launchers: exactly one runs" '[ "$nl" = 1 ] && [ "$(grep -c "\"agent\":1,\"label\":\"a1\",.*start" meta_1/launch_manifest.jsonl)" = 1 ]'
kill -TERM $(cat meta_1/.lock/launcher) 2>/dev/null; wait $B 2>/dev/null
setup; mkdir -p meta_1/.lock; echo 999999 > meta_1/.lock/launcher; : > meta_1/.lock/groups
check "stale lock blocks launch until --reclaim" '[ "$(run)" = 1 ] && bash "$S/launch_workers.sh" --reclaim meta_1 >/dev/null && [ "$(run)" = 0 ]'
setup; run >/dev/null; printf '#!/bin/sh\ntouch "$1/HOOKRAN"\n' > meta_1/after_agent.sh; chmod +x meta_1/after_agent.sh; rm -f meta_1/agent_*/.after_agent.done; touch meta_1/STOP; rc=$(run)
check "STOP blocks a pending after_agent hook" '[ "$rc" = 3 ] && [ ! -f meta_1/agent_1/HOOKRAN ]'
setup; FAKE_MODE=badmodel run >/dev/null; rc=$(FAKE_MODE=flaky FAKE_COUNTER=$T/cnt run 1)
check "old config error in the log does not block a retry" '[ "$rc" = 0 ]'; rm -f "$T/cnt"
setup; t0=$(date +%s); bash "$S/worker_status.sh" meta_1 --wait 60 >/dev/null; dt=$(( $(date +%s) - t0 ))
check "status --wait returns at once when no launcher runs" '[ "$dt" -le 1 ]'
check "status --wait rejects a bad deadline" '! bash "$S/worker_status.sh" meta_1 --wait x >/dev/null 2>&1'
FAKE_MODE=hang bash "$S/launch_workers.sh" meta_1 > meta_1/launch.log 2>&1 & L=$!; sleep 1; echo old > meta_1/failed.log; touch -d '1 hour ago' meta_1/failed.log
t0=$(date +%s); timeout 30 bash "$S/worker_status.sh" meta_1 --wait 3 >/dev/null; w=$?; dt=$(( $(date +%s) - t0 ))
check "status --wait keeps its deadline and ignores an old failed.log" '[ "$w" = 0 ] && [ "$dt" -ge 3 ] && [ "$dt" -le 6 ] && kill -0 $L 2>/dev/null'
kill -TERM $L; wait $L 2>/dev/null
setup; rc=$(run); rc2=$(run); check "re-run after completion is a no-op success" '[ "$rc2" = 0 ] && [ "$(grep -c "session exit" meta_1/agent_1/sessions.log)" = 3 ]'

# usage_report fixtures (fake HOME)
export HOME=$T/home; P=$T/home/proj; mkdir -p "$P" "$P-sibling" "$HOME/.codex/sessions/2026/01/01"
cf=$HOME/.codex/sessions/2026/01/01/rollout-2026-01-01T09-00-00-x.jsonl
tc() { printf '{"timestamp":"%s","type":"event_msg","payload":{"type":"token_count","info":{"total_token_usage":{"n":%s},"last_token_usage":{"input_tokens":%s,"cached_input_tokens":%s,"output_tokens":5}}}}\n' "$@"; }
{ printf '{"timestamp":"2026-01-01T09:00:00Z","type":"session_meta","payload":{"id":"s1","cwd":"%s"}}\n' "$P"
  tc 2026-01-01T09:30:00Z 1 100 50; tc 2026-01-01T10:30:00Z 2 200 100; tc 2026-01-01T10:30:01Z 2 200 100; tc 2026-01-01T12:30:00Z 3 400 0; } > "$cf"
sed "s#$P\"#$P-sibling\"#; s/s1/s2/" "$cf" > "${cf%x.jsonl}y.jsonl"
cd "$P"; out=$(python3 "$S/usage_report.py" codex --cwd . --since 2026-01-01T10:00 --until 2026-01-01T12:00)
check "usage: relative cwd, event window, sibling excluded, duplicate total skipped" 'echo "$out" | tail -1 | grep -q "\"calls\": 1, \"input\": 200"'
out=$(python3 "$S/usage_report.py" codex --session "$cf"); check "usage: --session for codex" 'echo "$out" | tail -1 | grep -q "\"calls\": 3"'
# Claude Code session fixture: window filter, cwd, worker tagging, sub-agent
CP=$HOME/.claude/projects/$(echo "$P" | sed 's/[^A-Za-z0-9]/-/g'); mkdir -p "$CP/sess1/subagents"
ev() { printf '{"type":"assistant","timestamp":"%s","cwd":"%s","message":{"id":"%s","model":"m","usage":{"input_tokens":1,"cache_read_input_tokens":%s,"cache_creation_input_tokens":0,"output_tokens":2},"content":[]}}\n' "$@"; }
{ printf '{"type":"user","cwd":"%s","message":{"content":"You are agent 2 of meta-iteration meta_1 of an automodel search"}}\n' "$P"
  ev 2026-01-01T09:00:00Z "$P" a 9; ev 2026-01-01T10:30:00Z "$P" b 99; ev 2026-01-01T10:30:00Z "$P" b 99; } > "$CP/sess1.jsonl"
ev 2026-01-01T10:45:00Z "$P" c 49 > "$CP/sess1/subagents/agent-x.jsonl"
cd "$P"; out=$(python3 "$S/usage_report.py" claude --since 2026-01-01T10:00 --until 2026-01-01T12:00)
check "usage (claude): worker tag" 'echo "$out" | grep -q "\"role\": \"worker\".*\"agent\": 2"'
check "usage (claude): window, duplicate message counted once, sub-agent" 'echo "$out" | tail -1 | grep -q "\"calls\": 2, \"input\": 150"'
check "usage: malformed or reversed bounds are errors" '! python3 "$S/usage_report.py" claude --since 2026-13-45 >/dev/null 2>&1 && ! python3 "$S/usage_report.py" claude --since 2026-01-02 --until 2026-01-01 >/dev/null 2>&1'
mf=$HOME/.codex/sessions/2026/01/01/rollout-2026-01-01T09-00-00-m.jsonl
{ printf '{"timestamp":"2026-01-01T09:00:00Z","type":"session_meta","payload":{"id":"s3","cwd":"%s"}}\n' "$P"
  printf '{"timestamp":"2026-01-01T10:00:00Z","type":"turn_context","payload":{"model":"A","effort":"low"}}\n'; tc 2026-01-01T10:30:00Z 5 10 0
  printf '{"timestamp":"2026-01-01T13:00:00Z","type":"turn_context","payload":{"model":"B","effort":"high"}}\n'; tc 2026-01-01T13:30:00Z 6 10 0; } > "$mf"
out=$(python3 "$S/usage_report.py" codex --session "$mf" --since 2026-01-01T10:00 --until 2026-01-01T12:00)
check "usage: model label from counted calls only" 'echo "$out" | head -1 | grep -q "\"model\": \"A\", \"effort\": \"low\""'
cd /; echo "passed $pass, failed $failn"; [ "$failn" -eq 0 ]
