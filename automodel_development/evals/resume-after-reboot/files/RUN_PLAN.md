# Run plan — rd_terms (version 2, 2026-11-18)

## Heavy search
### A. Setup
3. **Decision rule:** "Among candidates with 0 ≤ u ≤ 1 everywhere on the fitted domain, rank by validation RMSE (lower
   is better), ties within 0.0005 grouped by fewer terms; a replacement must improve on the incumbent by ≥ 0.0005."
   [user chose]
6. **External evidence:** none: exploratory, no independent check [user chose]
7. **Evaluation budget:** 300 scored fits, 60 h wall time, 6,000 core-h, all counted by the harness [user chose].
   Token budget (guide): ~1.7M per meta-iteration [proposed, accepted]
9. **Execution:** Glamdring via `glam`; workers run locally with acceptEdits and `Bash(python3:*) Bash(glam:*)` only
   [user chose]

### B. Search
12. **Mode and orchestration:** agents iterate; detached workers with phase sessions (`job_state.sh`) [delegated]
13. **M, S, I:** M = 4, S = 3, I = 5 [delegated]
17. **Progress and pauses:** progress message after each meta-iteration; pause for review between meta-iterations [user chose]
18. **Delegated changes:** directions, seeds, S and I within the budget [user chose]

## Approvals and changes
- 2026-11-12 — v1 part A approved by the user
- 2026-11-18 — v2 (part B; M raised from 3 to 4) approved by the user
