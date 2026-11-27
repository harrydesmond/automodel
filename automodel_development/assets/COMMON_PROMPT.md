# Common brief — meta_<m>

> Copy to `meta_m/COMMON_PROMPT.md` and fill the sections the search uses. With reduced context (the launcher's
> default), this file, the agent's `DIRECTION.md` and `WORKER_RULES.md` are the worker's only project context, so
> write rules it can act on, not the reasoning behind the plan. The launcher's own prompt covers `notes.md`,
> `exchange.md`, `STATE.md` hand-offs, `.job` receipts, `STOP` and the final reply; in-session agents get the
> applicable ones (`notes.md`, the final reply) from you instead.

## Goal and decision rule
<what the model is for; the decision rule verbatim from RUN_PLAN.md with its protocol version; the hard gates applied
during the search and how they are checked>

## Harness
<commands: submit (and wait, or under phase sessions return after the `.job` receipt) and, where used, harvest and
record a failure; the shared tools; where records (and any card) are and how to read them>

## Budget
<this agent's share: screens and scored fits per attempt and in total; soft guide for model calls per attempt and
per session>

## An attempt
<one structural modification from the parent, or the assigned bounded control (a convergence, recalibration or
execution comparison, whose gains are recorded as such, not as discoveries); screen first if fits are expensive; it
ends with its outcome recorded through the harness (result or failure, short rationale) and no job pending; continue
from the better of attempt and parent or, in an exploratory direction, from a worse but valid candidate>

## Waiting and context
<the rules of `resources.md` §3 that a worker can act on, with the soft guide for ending a session>

## Shared tools
<the shared-tools rules of `phases/3_iterate.md` (Launch), as they apply to a worker>

## Blockers
<when the plan, the data or a shared tool contradicts what you observe: one line with the evidence in
`agent_s/BLOCKER.md`, then continue with unaffected work or record the attempt as failed>

## Scope
<write roots (own folder and `tools/`); data and paths not to read (reserved data and results on them, anything else
the plan blinds); forbidden actions; network and compute limits>

## summary.md
<the summary contents and length of `resources.md` §3>
