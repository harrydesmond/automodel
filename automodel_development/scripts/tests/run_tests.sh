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
setup; rc=$(FAKE_MODE=empty run); check "empty outputs are not success (exit 1)" '[ "$rc" = 1 ] && grep -q FAILED meta_1/failed.log'
setup; rc=$(FAKE_MODE=badmodel run); check "configuration error fails at once" '[ "$rc" = 1 ] && [ "$(grep -c "session exit" meta_1/agent_1/sessions.log)" = 1 ]'
setup; rc=$(FAKE_MODE=flaky FAKE_COUNTER=$T/cnt run 1); check "transient failure is retried" '[ "$rc" = 0 ]'; rm -f "$T/cnt"
setup; printf '#!/bin/sh\nexit 17\n' > meta_1/after_agent.sh; chmod +x meta_1/after_agent.sh; rc=$(run)
check "failing after_agent hook fails the run" '[ "$rc" = 1 ] && grep -q "after_agent.sh exit 17" meta_1/failed.log'
setup; touch meta_1/STOP; rc=$(run); check "STOP: nothing starts, exit 3" '[ "$rc" = 3 ] && [ ! -d meta_1/agent_1/attempt_1 ]'
setup; FAKE_MODE=hang bash "$S/launch_workers.sh" meta_1 > meta_1/launch.log 2>&1 & L=$!; sleep 2
check "second launcher refused while one runs" '[ "$(run)" = 1 ]'
kill -TERM $L; wait $L 2>/dev/null; sleep 1
check "launcher TERM stops its workers and clears markers" '! pgrep -x sleep -a 2>/dev/null | grep -q "sleep 300" && [ ! -f meta_1/.launcher.pid ] && [ ! -f meta_1/agent_1/.owner ]'
setup; FAKE_MODE=badmodel run >/dev/null; rc=$(FAKE_MODE=flaky FAKE_COUNTER=$T/cnt run 1)
check "old config error in the log does not block a retry" '[ "$rc" = 0 ]'; rm -f "$T/cnt"
setup; echo old > meta_1/failed.log; touch -d '1 hour ago' meta_1/failed.log
FAKE_MODE=hang bash "$S/launch_workers.sh" meta_1 > meta_1/launch.log 2>&1 & L=$!
t0=$(date +%s); timeout 30 bash "$S/worker_status.sh" meta_1 --wait 6 >/dev/null; w=$?; dt=$(( $(date +%s) - t0 ))
check "status --wait is not ended by an old failed.log" '[ "$w" = 0 ] && [ "$dt" -ge 6 ] && kill -0 $L 2>/dev/null'
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
check "usage (claude): window, duplicate message counted once, worker tag, sub-agent" 'echo "$out" | grep -q "\"role\": \"worker\", \"model\": \"m\", \"effort\": null, \"agent\": 2" || echo "$out" | grep -q "\"agent\": 2"; echo "$out" | tail -1 | grep -q "\"calls\": 2, \"input\": 150"'
cd /; echo "passed $pass, failed $failn"; [ "$failn" -eq 0 ]
