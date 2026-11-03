# Run plan — <project> (<date>, version <n>)

> Copy to the project root as `RUN_PLAN.md`. Fill every line, marking each **[you chose]** (the user decided) or
> **[assumed: …]** (your default, with a few words of reason). Questions the user skipped or left half-answered appear
> here as [assumed]. Keep it to about one screen. Show it to the user and get explicit approval (or amendments) at
> the two points below; nothing costly runs before that. Re-approve if a [you chose] item changes.

## A. Setup — approve at the end of Phase 1, before Phase 2 spends real compute
1. **Goal and claim:** <what the model is for; what will be claimed at the end>
2. **Data:** <files, rows used, cleaning>
3. **Selection score:** <formula; the code that computes it; direction; tie rule>
4. **Physical / domain requirements:** <each one marked hard gate (candidate rejected) / penalised (in the score) /
   reported only>
5. **Search space:** <operators, constants and literals allowed; complexity limits; forbidden tricks>
6. **External check (Phase 4):** <held-out set / independent data / out-of-range constraints / none (agreed), with
   what that leaves unpriced>
7. **Fit settings:** <screens / scored attempts / final refits: restarts, seeds, time limits>
8. **References to reproduce:** <which incumbents or published results, at which settings; expected time>
9. **Where computation runs:** <local / cluster; cores; limits>
10. **Checks:** <adopted; N/A because …>
11. **Search size:** <light / heavy, why>; **estimate** <evaluation time; total usage (share of allowance), wall time,
    compute for the search as currently imagined>

## B. Search — approve before the first Phase 3 launch
12. **Mode and orchestration:** <agents iterate / batch proposals; in-session sub-agents / hybrid workers>
13. **M (or stop rule), S, I:** <…>
14. **Directions and seeds per agent:** <one line each>
15. **Models and effort:** <meta-agent; sub-agents (per class if heavy)>
16. **Estimate:** <usage (share of allowance), wall time, compute — from the Phase 2 calibration>
17. **Between meta-iterations:** <report and continue (light default) / pause for review and guidance (heavy
    default)>; a short progress message is sent after every meta-iteration either way
18. **Changes the meta-agent may make without asking:** <e.g. directions, seeds, S and I within the estimate;
    anything that changes items 1–11 or the estimate materially needs approval>
