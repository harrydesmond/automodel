# Run plan — <project> (version <n>, <date>)

> Light search. Copy to the project root as `RUN_PLAN.md`: the authoritative record of decisions. Mark each line
> **[user chose]**, **[delegated]** or **[proposed]** (`SKILL.md`); record approvals and later changes at the bottom.

## Plan (approved once)
1. **Goal and data:** <what the model is for; files and rows used>
2. **Decision rule:** "Among candidates satisfying <hard requirements, over which domain>, rank by <score, direction,
   tie grouping, margin needed to replace the incumbent>; <other checks> are reported only." Shown on: <a known
   reference, computed if cheap, and how it is ranked or rejected; known references the gates exclude>
3. **Evaluation:** <evaluator; references; fit settings; external check or "none: exploratory, no independent check">
   **Requirements and checks:** <each requirement a hard gate (during the search, or deferred) / in the score /
   reported only; how the search enforces each gate; complexity limits; checks adopted, and omissions that limit a
   claim>
4. **Work:** <fit and elapsed-time caps as one ledger (setup, search, consolidation, protected final checks); the kind
   of each limit and how it is enforced; initial M, S, I; stop rule; where computation runs>
5. **Authority and progress:** <what you may change without asking; pause between meta-iterations (default off)>

## Approvals and changes
- <date> — <version> approved by the user (<scope>)
