# Common brief — meta_<m>

> Copy to `meta_m/COMMON_PROMPT.md` and fill every section. With isolation on, this file, the agent's `DIRECTION.md`
> and `WORKER_RULES.md` are all the context a worker gets, so write rules it can act on, not the reasoning behind the
> plan. The launcher's own prompt already covers `notes.md`, `exchange.md`, `STATE.md` hand-offs, `.job` receipts,
> `STOP` and the final reply: do not restate them.

## Goal and decision rule
<what the model is for; the decision rule verbatim from RUN_PLAN.md with its protocol version; hard gates and how
they are checked>

## Harness
<commands: submit (and wait, or under phase sessions return after the `.job` receipt), harvest, record a failure;
the toolkit; where records and cards are and how to read a card>

## Budget
<this agent's share: screens and scored fits per attempt and in total; soft guide for model calls per attempt and
per session>

## An attempt
<one structural modification (or the assigned control) from the parent; screen first if fits are expensive; what the
attempt directory holds when done; continue from the better of attempt and parent>

## Waiting and context
<the rules of `resources.md` §3 that a worker can act on: no polling; analysis in scripts that print compact
summaries; prose limits>

## Shared tools
<`tools/`, one line per tool in `tools/INDEX.md`, fixes logged in `tools/CHANGES.md`; faults in anything that sets
scores, records or eligibility are reported, not edited>

## Blockers
<when the plan, the data or a shared tool contradicts what you observe: one line with the evidence in
`agent_s/BLOCKER.md`, then continue with unaffected work or record the attempt as failed>

## Scope
<write roots (own folder and `tools/`); data and paths not to read (reserved data, reference results); forbidden
actions; network and compute limits>

## summary.md
<≤ 300 words: record IDs, the best structure, each failure with its cause in one line, reusable components, the next
step>
