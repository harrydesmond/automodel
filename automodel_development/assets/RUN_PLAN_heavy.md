# Run plan — <project> (version <n>, <date>)

> Heavy search. Copy to the project root as `RUN_PLAN.md`: the authoritative record of decisions. Mark each line
> **[user chose]**, **[delegated]** or **[proposed]** (`SKILL.md`); record approvals and later changes at the bottom.

## A. Setup — approve at the end of Phase 1
1. **Goal and claims:** <use of the model; region and quantities the final claims will cover>
2. **Data:** <files, cleaning, splits or folds; provenance of inherited parameters>
3. **Decision rule:** "Among candidates satisfying <hard requirements, over which domain>, rank by <score, direction,
   tie grouping, margin needed to replace the incumbent>; <other checks> are reported only." Shown on: <a known
   reference and how it is ranked or rejected; known references the gates exclude>; the code that implements it and
   the protocol version
4. **Requirements:** <each a hard gate (during the search, or deferred), penalised or reported only; statistic,
   population; how the search enforces each gate>
5. **Search space:** <operators, constants and literals allowed; complexity accounting; forbidden tricks>
6. **External evidence:** <reserved data and how they are locked; prior exposure; what may be refitted at the final
   check; fresh evidence for later claims; or none, with what that leaves unpriced (`phases/1_setup.md` §4)>
7. **Evaluation budget:** <the ledger and caps of `phases/1_setup.md` §6, screens and scored fits per attempt,
   seeds/restarts per stage; the kind of each limit and how it is enforced>. **Token budget** (estimate, not
   enforced): <per meta-iteration; reported against actual after each one>
8. **References:** <which, at which settings; expected time>
9. **Execution:** <where computation runs; in-session sub-agents or detached workers; if detached, worker
   permissions (write roots, network, compute), where the launcher runs, and whether the run continues while the user
   is away>
10. **Checks:** <adopted from checks.md; omissions that limit a claim>
11. **Estimate:** <usage, wall time, compute, including agreed finalization and contingency; what is unmeasured>

## B. Search — approve after Phase 2's calibration, before the first launch
12. **Working mode:** <agents iterate / batch proposals>
13. **M (or stop rule), S, I:** <…>
14. **Directions and seeds:** <one line per agent; which directions are exploratory>
15. **Models and effort:** <meta-agent; sub-agents; alternatives offered>
16. **Estimate from calibration:** <usage, wall time, compute>
17. **Progress and pauses:** <update cadence; pause between meta-iterations (default on); for unattended periods, the
    work queued and the idle time the user accepted>
18. **Delegated changes:** <e.g. directions, seeds, S and I within the budget; anything else needs approval>

## Approvals and changes
- <date> — <version> approved by the user (<scope>)
