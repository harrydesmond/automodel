"""Per-agent token usage of a meta-iteration, read from the framework's own session logs (no API access needed).

    python usage_report.py codex  --cwd <project dir> --since 2026-11-01T10:00 [--until ...]
    python usage_report.py claude --cwd <project dir> --since 2026-11-01T10:00 [--until ...]   (all sessions, workers too)
    python usage_report.py claude --session ~/.claude/projects/<proj>/<session-id>.jsonl [--match "meta_3 agent"]

Codex: ~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl (token_count events; turn_context gives model/effort;
session_meta.source.subagent marks sub-agents). Claude Code: <session>.jsonl plus <session>/subagents/agent-*.jsonl
(message.usage; .meta.json holds the sub-agent description). For each thread: model calls, input tokens (cached part),
output tokens, median context, and the share of input spent on calls that follow an idle tool call (sleep, wait,
wait/poll scripts) -- the usual dominant cost when evaluations are long. Output: one JSON line per session (and per
in-session sub-agent), then a TOTAL line; it goes to the usage log (assets/resources.md). --since/--until are UTC ISO
times compared with each session's START, so per-attempt worker sessions are counted exactly, while a long-running
meta-agent session is counted whole (pass --session for it).
"""
import argparse
import glob
import json
import os
import re
import statistics

IDLE = ('sleep', 'wait', 'wait_agent')                        # tool names
POLL = re.compile(r'\bsleep\b|\bwait\b|_wait\b|--wait|squeue|sacct|qstat')  # commands that wait or poll


def _idle(name, args):
    return name in IDLE or bool(POLL.search(args))


def codex(a):
    rows = []
    for f in sorted(glob.glob(os.path.expanduser('~/.codex/sessions/*/*/*/rollout-*.jsonl'))):
        meta, model, eff, last, first, n, ctx, tok = {}, None, None, 'work', None, 0, [], dict(idle=0, work=0, out=0, cached=0)
        for line in open(f):
            try:
                r = json.loads(line)
            except ValueError:
                continue
            p, t = r.get('payload', {}), r.get('type')
            first = first or r.get('timestamp')
            if t == 'session_meta' and not meta:      # forked sessions replay the parent's session_meta: keep the first
                meta = dict(p)
                sp = (p.get('source') or {}).get('subagent', {}) if isinstance(p.get('source'), dict) else {}
                if isinstance(sp, dict) and isinstance(sp.get('thread_spawn'), dict):
                    meta['label'] = sp['thread_spawn'].get('agent_path') or sp['thread_spawn'].get('agent_nickname') or ''
            elif t == 'response_item' and p.get('type') == 'message' and p.get('role') == 'user' and 'label' not in meta:
                txt = ' '.join(c.get('text', '') for c in p.get('content') or [] if isinstance(c, dict)).strip()
                if txt and not txt.startswith(('#', '<')):
                    meta['label'] = ' '.join(txt.split())
            elif t == 'turn_context':
                model, eff = p.get('model'), p.get('effort') or p.get('reasoning_effort')
            elif t == 'response_item' and p.get('type') in ('function_call', 'custom_tool_call'):
                last = 'idle' if _idle(p.get('name', ''), str(p.get('arguments') or p.get('input') or '')) else 'work'
            elif t == 'event_msg' and p.get('type') == 'token_count' and p.get('info'):
                u = p['info'].get('last_token_usage') or {}
                n += 1; ctx.append(u.get('input_tokens', 0))
                tok[last] += u.get('input_tokens', 0); tok['out'] += u.get('output_tokens', 0)
                tok['cached'] += u.get('cached_input_tokens', 0)
        if not n or not meta.get('cwd', '').startswith(a.cwd) or (first or '') < a.since or (a.until and first > a.until):
            continue
        sub = isinstance(meta.get('source'), dict) and 'subagent' in meta['source']
        rows.append(dict(thread=(os.path.basename(f)[8:27] + ' ' + meta.get('label', ''))[:60],
                         role='sub-agent' if sub else 'main', model=model, effort=eff,
                         calls=n, **_fmt(tok, ctx)))
    return rows


def _first(f):
    """Timestamp, working directory and opening user text of a Claude Code session file."""
    ts, cwd, txt = None, None, ''
    for line in open(f):
        try:
            r = json.loads(line)
        except ValueError:
            continue
        ts = ts or r.get('timestamp')
        cwd = cwd or r.get('cwd')
        m = r.get('message') if isinstance(r.get('message'), dict) else {}
        if r.get('type') == 'user' and not txt:
            c = m.get('content')
            txt = c if isinstance(c, str) else ' '.join(x.get('text', '') for x in c or [] if isinstance(x, dict))
        if ts and txt and cwd:
            break
    return ts or '', cwd or '', ' '.join(txt.split())


def claude(a):
    if a.session:
        return _claude_session(a, a.session)
    enc = re.sub(r'[^A-Za-z0-9]', '-', os.path.abspath(a.cwd))
    rows = []
    for f in sorted(glob.glob(os.path.expanduser('~/.claude/projects/%s*/*.jsonl' % enc))):
        ts, cwd, txt = _first(f)
        root = os.path.abspath(a.cwd)
        if not (cwd == root or cwd.startswith(root + os.sep)) or ts < a.since or (a.until and ts > a.until):
            continue
        rows += _claude_session(a, f, label=(os.path.basename(f)[:8] + ' ' + txt)[:60])
    return rows


def _claude_session(a, session, label='main'):
    files = [(session, label)]
    d = session[:-6]
    for f in sorted(glob.glob(os.path.join(d, 'subagents', 'agent-*.jsonl'))):
        m = json.load(open(f[:-6] + '.meta.json')) if os.path.exists(f[:-6] + '.meta.json') else {}
        if a.match in m.get('description', ''):
            files.append((f, m.get('description', '?')))
    rows = []
    for f, desc in files:
        seen, last, n, ctx, model = set(), 'work', 0, [], None
        tok = dict(idle=0, work=0, out=0, cached=0, cache_write=0)
        for line in open(f):
            try:
                r = json.loads(line)
            except ValueError:
                continue
            m = r.get('message') if isinstance(r.get('message'), dict) else {}
            if r.get('type') != 'assistant':
                continue
            u, mid = m.get('usage') or {}, m.get('id')
            if u and mid not in seen:
                seen.add(mid); n += 1; model = m.get('model', model)
                inp = u.get('input_tokens', 0) + u.get('cache_read_input_tokens', 0) + u.get('cache_creation_input_tokens', 0)
                ctx.append(inp); tok[last] += inp; tok['out'] += u.get('output_tokens', 0)
                tok['cached'] += u.get('cache_read_input_tokens', 0); tok['cache_write'] += u.get('cache_creation_input_tokens', 0)
            for c in m.get('content') if isinstance(m.get('content'), list) else []:
                if isinstance(c, dict) and c.get('type') == 'tool_use':
                    last = 'idle' if _idle(c.get('name', ''), json.dumps(c.get('input'))) else 'work'
        if n:
            rows.append(dict(thread=desc[:60], role='main' if desc == label else 'sub-agent', model=model, effort=None,
                             calls=n, **_fmt(tok, ctx)))
    return rows


def _fmt(tok, ctx):
    tot = tok['idle'] + tok['work']
    out = dict(input_M=round(tot / 1e6, 1), cached_M=round(tok['cached'] / 1e6, 1), output_M=round(tok['out'] / 1e6, 3),
               median_ctx_k=round(statistics.median(ctx) / 1e3), idle_input_share=round(tok['idle'] / tot, 2) if tot else None)
    if 'cache_write' in tok:
        out['cache_write_M'] = round(tok['cache_write'] / 1e6, 1)
    return out


if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('framework', choices=('codex', 'claude'))
    ap.add_argument('--cwd', default=os.getcwd()); ap.add_argument('--since', default=''); ap.add_argument('--until', default='')
    ap.add_argument('--session'); ap.add_argument('--match', default='')
    a = ap.parse_args()
    rows = codex(a) if a.framework == 'codex' else claude(a)
    for r in rows:
        print(json.dumps(r))
    keys = ('calls', 'input_M', 'output_M')
    tot = {k: round(sum(r[k] for r in rows), 3) for k in keys}
    tot['idle_input_share'] = round(sum(r['input_M'] * (r['idle_input_share'] or 0) for r in rows)
                                    / max(1e-9, sum(r['input_M'] for r in rows)), 2)
    print(json.dumps(dict(thread='TOTAL', **tot)))
