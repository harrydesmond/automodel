# Run plan — <project> (version <n>, <date>)

> Copy to the project root as `RUN_PLAN.md`; it is the authoritative record of decisions (CONTEXT.md points to it).
> Mark each line **[user chose]**, **[delegated]** or **[proposed]**. Resolve [proposed] items that change the
> objective, permitted work or budget before approval. Record approvals and later changes at the bottom.

## Light search (one compact plan, approved once)
1. **Goal and data:** <what the model is for; files and rows used>
2. **Decision rule:** "Among candidates satisfying <hard requirements, over which domain>, rank by <score, direction,
   tie grouping, margin needed to replace the incumbent>; <other checks> are reported only." Shown on: <a known
   reference, computed if cheap, and how it is ranked or rejected; known references the gates exclude>
3. **Evaluation:** <evaluator; references; fit settings; external check or "none: exploratory, no independent check">
4. **Work:** <fit cap and elapsed-time cap; initial M, S, I; stop rule; where computation runs>
5. **Authority and progress:** <what you may change without asking; pause between meta-iterations (default off)>

## Heavy search
### A. Setup — approve at the end of Phase 1
1. **Goal and claims:** <use of the model; region and quantities the final claims will cover>
2. **Data:** <files, cleaning, splits or folds; provenance of inherited parameters>
3. **Decision rule:** as light item 2, with the code that implements it and the protocol version
4. **Requirements:** <each one a hard gate (rejects) / penalised (in the score) / reported only; its statistic and
   population>
5. **Search space:** <operators, constants and literals allowed; complexity accounting; forbidden tricks>
6. **External evidence:** <reserved data and how it is locked; prior exposure (e.g. reference benchmarking, sibling
   runs on the same pool); what may be refitted at the final check; fresh-evidence access for later claims; or none, with what that leaves unpriced>
7. **Evaluation budget:** <screens and scored fits per attempt; run-wide fit, wall-time and compute caps, counting
   baselines, failures, refits and recombinations; seeds/restarts per stage>
8. **References:** <which, at which settings; expected time>
9. **Execution:** <where computation runs; worker permissions (write roots, network, compute) if detached>
10. **Checks:** <adopted from checks.md; N/A because …>
11. **Estimate:** <usage, wall time, compute, including agreed finalization and contingency; what is
    unmeasured>

### B. Search — approve after Phase 2's calibration, before the first launch
12. **Mode and orchestration:** <agents iterate / batch proposals; in-session / hybrid workers>
13. **M (or stop rule), S, I:** <…>
14. **Directions and seeds:** <one line per agent>
15. **Models and effort:** <meta-agent; sub-agents; alternatives offered>
16. **Estimate from calibration:** <usage, wall time, compute>
17. **Progress and pauses:** <update cadence; pause between meta-iterations (default on)>
18. **Delegated changes:** <e.g. directions, seeds, S and I within the budget; anything else needs approval>

## Approvals and changes
- <date> — <version> approved by the user (<scope>)
