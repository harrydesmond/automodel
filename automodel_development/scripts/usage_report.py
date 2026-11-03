#!/usr/bin/env python3
"""Token usage per session over a time window, read from the frameworks' own local session logs (no API access).

    python usage_report.py codex  --cwd <project dir> --since 2026-11-01T10:00 [--until ...]
    python usage_report.py claude --cwd <project dir> --since 2026-11-01T10:00 [--until ...]
    python usage_report.py codex|claude --session <session file> [--since ...]

Usage events are filtered by their own timestamps (UTC, ISO), so a session that started before the window (e.g. a
meta-agent that began in Setup) contributes exactly its calls inside the window, and nothing outside it. Sessions are
those whose working directory is the project directory or below it.
Codex: ~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl (token_count events; repeated cumulative totals are skipped).
Claude Code: ~/.claude/projects/<encoded cwd>/<session>.jsonl and <session>/subagents/agent-*.jsonl (message.usage).
One JSON line per session or in-session sub-agent, then a TOTAL line. Fields: calls; input (gross, = uncached + cache
reads + cache writes); uncached, cache_read, cache_write (Claude only), output; median context; role (worker if the
opening prompt is a launch_workers.sh prompt, sub-agent, or main); agent/meta for workers (see launch_manifest.jsonl);
idle_input_share = share of input on calls that follow a wait/poll tool call (a heuristic, not a cost attribution).
Token counts are not money or allowance: prices, caching and plan rules differ.
"""
import argparse
import datetime as dt
import glob
import json
import os
import re
import statistics

IDLE = ('sleep', 'wait', 'wait_agent')
POLL = re.compile(r'\bsleep\b|\bwait\b|_wait\b|--wait|squeue|sacct|qstat')
WORKER = re.compile(r'You are agent (\d+) of meta-iteration ([A-Za-z0-9_.\/-]+)')


def _idle(name, args):
    return name in IDLE or bool(POLL.search(args))


def _t(s):
    """Parse an ISO time (naive = UTC) to an aware datetime; None if empty or unparsable."""
    if not s:
        return None
    try:
        t = dt.datetime.fromisoformat(s.replace('Z', '+00:00'))
    except ValueError:
        return None
    return t if t.tzinfo else t.replace(tzinfo=dt.timezone.utc)


class Acc:
    def __init__(self):
        self.calls, self.ctx = 0, []
        self.k = dict(uncached=0, cache_read=0, cache_write=0, output=0, idle=0)

    def add(self, uncached, cache_read, cache_write, output, idle):
        gross = uncached + cache_read + cache_write
        self.calls += 1; self.ctx.append(gross)
        self.k['uncached'] += uncached; self.k['cache_read'] += cache_read; self.k['cache_write'] += cache_write
        self.k['output'] += output
        if idle:
            self.k['idle'] += gross

    def row(self, **meta):
        gross = self.k['uncached'] + self.k['cache_read'] + self.k['cache_write']
        return dict(meta, calls=self.calls, input=gross, uncached=self.k['uncached'], cache_read=self.k['cache_read'],
                    cache_write=self.k['cache_write'], output=self.k['output'],
                    median_ctx_k=round(statistics.median(self.ctx) / 1e3) if self.ctx else 0,
                    idle_input_share=round(self.k['idle'] / gross, 2) if gross else None)


def _inside(cwd, root):
    if not cwd:
        return False
    cwd = os.path.abspath(cwd)
    return cwd == root or cwd.startswith(root.rstrip(os.sep) + os.sep)


def _in_window(ts, a):
    t = _t(ts)
    return t is not None and (a.since is None or t >= a.since) and (a.until is None or t < a.until)


def _role(label, default):
    m = WORKER.search(label or '')
    return ('worker', int(m.group(1)), m.group(2)) if m else (default, None, None)


def codex_file(f, a, check_cwd=True):
    meta, label, model, eff, last, acc, prev, used = {}, '', None, None, 'work', Acc(), None, set()
    for line in open(f, errors='ignore'):
        try:
            r = json.loads(line)
        except ValueError:
            continue
        p, t = r.get('payload') or {}, r.get('type')
        if t == 'session_meta' and not meta:  # forked sessions replay the parent's session_meta: keep the first
            meta = dict(p)
            sp = p.get('source', {}).get('subagent', {}) if isinstance(p.get('source'), dict) else {}
            if isinstance(sp, dict) and isinstance(sp.get('thread_spawn'), dict):
                label = sp['thread_spawn'].get('agent_path') or sp['thread_spawn'].get('agent_nickname') or ''
        elif t == 'response_item' and p.get('type') == 'message' and p.get('role') == 'user' and not label:
            txt = ' '.join(c.get('text', '') for c in p.get('content') or [] if isinstance(c, dict)).strip()
            if txt and not txt.startswith(('#', '<')):
                label = ' '.join(txt.split())
        elif t == 'turn_context':
            model, eff = p.get('model', model), p.get('effort') or p.get('reasoning_effort') or eff
        elif t == 'response_item' and p.get('type') in ('function_call', 'custom_tool_call'):
            last = 'idle' if _idle(p.get('name', ''), str(p.get('arguments') or p.get('input') or '')) else 'work'
        elif t == 'event_msg' and p.get('type') == 'token_count' and p.get('info'):
            tot = p['info'].get('total_token_usage')
            if tot is not None:
                tot = json.dumps(tot, sort_keys=True)
                if tot == prev:      # repeated update of the same cumulative total: not a new call
                    continue
                prev = tot
            if not _in_window(r.get('timestamp'), a):
                continue
            u = p['info'].get('last_token_usage') or {}
            used.add((model, eff))
            inp, cached = u.get('input_tokens', 0), u.get('cached_input_tokens', 0)
            acc.add(inp - cached, cached, 0, u.get('output_tokens', 0), last == 'idle')
    if not acc.calls or (check_cwd and not _inside(meta.get('cwd'), a.cwd)):
        return []
    sub = isinstance(meta.get('source'), dict) and 'subagent' in meta['source']
    model, eff = next(iter(used)) if len(used) == 1 else ('mixed', None)   # settings of the counted calls only
    role, agent, mi = _role(label, 'sub-agent' if sub else 'main')
    out = acc.row(thread=(os.path.basename(f)[8:27] + ' ' + label)[:70], session=meta.get('id'), role=role,
                  model=model, effort=eff)
    out.pop('cache_write')
    if agent is not None:
        out.update(agent=agent, meta=mi)
    return [out]


def codex(a):
    files = [a.session] if a.session else sorted(glob.glob(os.path.expanduser('~/.codex/sessions/*/*/*/rollout-*.jsonl')))
    return [r for f in files for r in codex_file(f, a, check_cwd=not a.session)]


def claude_file(f, a, label, role):
    acc, last, seen, used = Acc(), 'work', set(), set()
    for line in open(f, errors='ignore'):
        try:
            r = json.loads(line)
        except ValueError:
            continue
        m = r.get('message') if isinstance(r.get('message'), dict) else {}
        if r.get('type') != 'assistant':
            continue
        u, mid = m.get('usage') or {}, m.get('id')
        if u and mid not in seen:      # several content blocks of one message share its usage: count once
            seen.add(mid)
            if _in_window(r.get('timestamp'), a):
                used.add(m.get('model'))
                acc.add(u.get('input_tokens', 0), u.get('cache_read_input_tokens', 0),
                        u.get('cache_creation_input_tokens', 0), u.get('output_tokens', 0), last == 'idle')
        for c in m.get('content') if isinstance(m.get('content'), list) else []:
            if isinstance(c, dict) and c.get('type') == 'tool_use':
                last = 'idle' if _idle(c.get('name', ''), json.dumps(c.get('input'))) else 'work'
    if not acc.calls:
        return []
    model = next(iter(used)) if len(used) == 1 else 'mixed'
    role, agent, mi = _role(label, role)
    out = acc.row(thread=label[:70], session=os.path.basename(f)[:-6], role=role, model=model, effort=None)
    if agent is not None:
        out.update(agent=agent, meta=mi)
    return [out]


def _opening(f):
    cwd, txt = None, ''
    for line in open(f, errors='ignore'):
        try:
            r = json.loads(line)
        except ValueError:
            continue
        cwd = cwd or r.get('cwd')
        m = r.get('message') if isinstance(r.get('message'), dict) else {}
        if r.get('type') == 'user' and not txt:
            c = m.get('content')
            txt = c if isinstance(c, str) else ' '.join(x.get('text', '') for x in c or [] if isinstance(x, dict))
        if cwd and txt:
            break
    return cwd, ' '.join((txt or '').split())


def claude(a):
    if a.session:
        sessions = [a.session]
    else:
        enc = re.sub(r'[^A-Za-z0-9]', '-', a.cwd)
        sessions = sorted(glob.glob(os.path.expanduser('~/.claude/projects/%s*/*.jsonl' % glob.escape(enc))))
    rows = []
    for f in sessions:
        cwd, txt = _opening(f)
        if not a.session and not _inside(cwd, a.cwd):
            continue
        rows += claude_file(f, a, (os.path.basename(f)[:8] + ' ' + txt), 'main')
        for g in sorted(glob.glob(os.path.join(f[:-6], 'subagents', 'agent-*.jsonl'))):
            mf = g[:-6] + '.meta.json'
            desc = json.load(open(mf)).get('description', '?') if os.path.exists(mf) else '?'
            if a.match in desc:
                rows += claude_file(g, a, desc, 'sub-agent')
    return rows


if __name__ == '__main__':
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('framework', choices=('codex', 'claude'))
    ap.add_argument('--cwd', default=os.getcwd()); ap.add_argument('--since', default=''); ap.add_argument('--until', default='')
    ap.add_argument('--session'); ap.add_argument('--match', default='', help='Claude: only sub-agents whose description contains this')
    a = ap.parse_args()
    a.cwd = os.path.abspath(os.path.expanduser(a.cwd))
    for name in ('since', 'until'):
        raw = getattr(a, name); parsed = _t(raw)
        if raw and parsed is None:
            ap.error(f'--{name} must be an ISO timestamp, e.g. 2026-11-03T10:00')
        setattr(a, name, parsed)
    if a.since and a.until and a.until <= a.since:
        ap.error('--until must be later than --since')
    rows = codex(a) if a.framework == 'codex' else claude(a)
    for r in rows:
        print(json.dumps(r))
    keys = ('calls', 'input', 'uncached', 'cache_read', 'cache_write', 'output')
    tot = {k: sum(r.get(k, 0) for r in rows) for k in keys}
    tot['idle_input_share'] = round(sum(r['input'] * (r['idle_input_share'] or 0) for r in rows) / tot['input'], 2) if tot['input'] else None
    print(json.dumps(dict(thread='TOTAL', **tot)))
